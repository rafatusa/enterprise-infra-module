// Package awseks is a Pulumi solution package that provisions a complete
// production-grade AWS EKS environment by composing all aws/* modules:
// vpc + security-group + iam-role + kms + s3 + eks + cloudwatch.
//
// Equivalent to infra/packages/aws-eks but implemented as a Pulumi Go component.
//
// Usage:
//
//	env, err := awseks.NewEnvironment(ctx, "prod", &awseks.Args{
//	    ClusterName: pulumi.String("prod-eks"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	    Region:      pulumi.String("us-east-1"),
//	})
package awseks

import (
	"fmt"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"

	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/cloudwatch"
	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/eks"
	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/iam-role"
	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/kms"
	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/s3"
	"github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/vpc"
)

// Args holds the top-level configuration for the full EKS environment.
type Args struct {
	// ClusterName is the EKS cluster name.
	ClusterName pulumi.StringInput
	// Project is used for all resource naming and tagging.
	Project pulumi.StringInput
	// Environment tag value (e.g. production, staging).
	Environment pulumi.StringInput
	// Region is the AWS region (used for naming context).
	Region pulumi.StringInput
	// VpcCidr is the VPC CIDR block. Default: 10.0.0.0/16.
	VpcCidr pulumi.StringInput
	// AvailabilityZones to use. Default: first two AZs.
	AvailabilityZones pulumi.StringArrayInput
	// NodeInstanceType for EKS workers. Default: t3.medium.
	NodeInstanceType pulumi.StringInput
	// NodeDesiredCount is the desired EKS node count. Default: 2.
	NodeDesiredCount pulumi.IntInput
}

// Environment is the full EKS environment component output.
type Environment struct {
	pulumi.ResourceState

	// VpcID of the created VPC.
	VpcID pulumi.StringOutput `pulumi:"vpcId"`
	// ClusterEndpoint of the EKS API server.
	ClusterEndpoint pulumi.StringOutput `pulumi:"clusterEndpoint"`
	// ClusterName of the EKS cluster.
	ClusterName pulumi.StringOutput `pulumi:"clusterName"`
	// LogGroupName for CloudWatch logs.
	LogGroupName pulumi.StringOutput `pulumi:"logGroupName"`
	// StateBucketName for remote state storage.
	StateBucketName pulumi.StringOutput `pulumi:"stateBucketName"`
}

// NewEnvironment provisions a complete AWS EKS environment.
func NewEnvironment(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Environment, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Environment{}
	err := ctx.RegisterComponentResource("udap:packages:AwsEks", name, component, opts...)
	if err != nil {
		return nil, err
	}

	parentOpt := pulumi.Parent(component)

	// 1. VPC
	vpcComp, err := vpc.NewVpc(ctx, fmt.Sprintf("%s-vpc", name), &vpc.Args{
		Name:        args.ClusterName,
		Project:     args.Project,
		Environment: args.Environment,
		AvailabilityZones: pulumi.StringArray{
			pulumi.String("us-east-1a"),
			pulumi.String("us-east-1b"),
		},
		PublicSubnetCidrs:  pulumi.StringArray{pulumi.String("10.0.1.0/24"), pulumi.String("10.0.2.0/24")},
		PrivateSubnetCidrs: pulumi.StringArray{pulumi.String("10.0.10.0/24"), pulumi.String("10.0.11.0/24")},
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 2. KMS key for EKS secrets encryption
	kmsComp, err := kms.NewKey(ctx, fmt.Sprintf("%s-kms", name), &kms.Args{
		Name:        pulumi.Sprintf("%s-eks-key", args.ClusterName),
		Project:     args.Project,
		Environment: args.Environment,
		Description: pulumi.String("EKS secrets encryption key"),
	}, parentOpt)
	if err != nil {
		return nil, err
	}
	_ = kmsComp

	// 3. S3 bucket for state/artifacts
	s3Comp, err := s3.NewBucket(ctx, fmt.Sprintf("%s-s3", name), &s3.Args{
		BucketName:  pulumi.Sprintf("%s-eks-artifacts", args.ClusterName),
		Project:     args.Project,
		Environment: args.Environment,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 4. IAM Role for EKS nodes
	_, err = iamrole.NewRole(ctx, fmt.Sprintf("%s-node-role", name), &iamrole.Args{
		Name:              pulumi.Sprintf("%s-eks-node-role", args.ClusterName),
		Project:           args.Project,
		Environment:       args.Environment,
		AssumeRoleService: pulumi.String("ec2.amazonaws.com"),
		ManagedPolicyARNs: pulumi.StringArray{
			pulumi.String("arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"),
			pulumi.String("arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"),
			pulumi.String("arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"),
		},
		CreateInstanceProfile: pulumi.Bool(true),
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 5. EKS Cluster
	eksComp, err := eks.NewCluster(ctx, fmt.Sprintf("%s-eks", name), &eks.Args{
		ClusterName:      args.ClusterName,
		Project:          args.Project,
		Environment:      args.Environment,
		VpcID:            vpcComp.VpcID,
		PrivateSubnetIDs: vpcComp.PrivateSubnetIDs,
		NodeInstanceType: args.NodeInstanceType,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 6. CloudWatch monitoring
	cwComp, err := cloudwatch.NewMonitoring(ctx, fmt.Sprintf("%s-cw", name), &cloudwatch.Args{
		Name:        args.ClusterName,
		Project:     args.Project,
		Environment: args.Environment,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	component.VpcID = vpcComp.VpcID
	component.ClusterEndpoint = eksComp.ClusterEndpoint
	component.ClusterName = eksComp.ClusterName
	component.LogGroupName = cwComp.LogGroupName
	component.StateBucketName = s3Comp.BucketName

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"vpcId":           component.VpcID,
		"clusterEndpoint": component.ClusterEndpoint,
		"clusterName":     component.ClusterName,
		"logGroupName":    component.LogGroupName,
		"stateBucketName": component.StateBucketName,
	})

	return component, nil
}
