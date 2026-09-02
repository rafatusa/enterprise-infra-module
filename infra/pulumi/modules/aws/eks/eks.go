// Package eks provides a Pulumi component resource for an AWS EKS cluster
// with managed node groups, OIDC provider, and core add-ons.
// Mirrors infra/terraform/modules/aws/eks.
//
// Usage:
//
//	cluster, err := eks.NewCluster(ctx, "prod", &eks.Args{
//	    ClusterName:      pulumi.String("prod-eks"),
//	    Project:          pulumi.String("my-project"),
//	    Environment:      pulumi.String("production"),
//	    VpcID:            vpc.VpcID,
//	    PrivateSubnetIDs: vpc.PrivateSubnetIDs,
//	    KubernetesVersion: pulumi.String("1.33"),
//	})
package eks

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/eks"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the EKS cluster component.
type Args struct {
	// ClusterName is the EKS cluster name.
	ClusterName pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// VpcID is the VPC the cluster is deployed in.
	VpcID pulumi.StringInput
	// PrivateSubnetIDs are the subnets for the node group.
	PrivateSubnetIDs pulumi.StringArrayInput
	// KubernetesVersion pins the EKS control plane version. Default: "1.33".
	KubernetesVersion pulumi.StringInput
	// NodeInstanceType is the EC2 type for worker nodes. Default: "t3.medium".
	NodeInstanceType pulumi.StringInput
	// NodeDesiredCount is the desired node count. Default: 2.
	NodeDesiredCount pulumi.IntInput
	// NodeMinCount is the minimum node count. Default: 1.
	NodeMinCount pulumi.IntInput
	// NodeMaxCount is the maximum node count. Default: 4.
	NodeMaxCount pulumi.IntInput
}

// Cluster is the component resource output.
type Cluster struct {
	pulumi.ResourceState

	ClusterName     pulumi.StringOutput `pulumi:"clusterName"`
	ClusterEndpoint pulumi.StringOutput `pulumi:"clusterEndpoint"`
	ClusterARN      pulumi.StringOutput `pulumi:"clusterArn"`
	OIDCProviderURL pulumi.StringOutput `pulumi:"oidcProviderUrl"`
	NodeGroupARN    pulumi.StringOutput `pulumi:"nodeGroupArn"`
	// ClusterCaCertificate is the base64-encoded cluster CA, needed to build
	// a kubeconfig. Treat as sensitive.
	ClusterCaCertificate pulumi.StringOutput `pulumi:"clusterCaCertificate"`
}

// NewCluster creates a new EKS cluster component resource.
func NewCluster(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Cluster, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Cluster{}
	err := ctx.RegisterComponentResource("udap:aws:EksCluster", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/eks"),
	}

	// Resolve optional inputs to their documented defaults. Never
	// type-assert a pulumi Input to a concrete type — callers legitimately
	// pass Outputs from other resources, which would panic.
	k8sVersion := args.KubernetesVersion
	if k8sVersion == nil {
		k8sVersion = pulumi.String("1.33")
	}

	nodeType := args.NodeInstanceType
	if nodeType == nil {
		nodeType = pulumi.String("t3.medium")
	}

	desiredSize := args.NodeDesiredCount
	if desiredSize == nil {
		desiredSize = pulumi.Int(2)
	}

	minSize := args.NodeMinCount
	if minSize == nil {
		minSize = pulumi.Int(1)
	}

	maxSize := args.NodeMaxCount
	if maxSize == nil {
		maxSize = pulumi.Int(4)
	}

	// Cluster IAM Role
	clusterRole, err := iam.NewRole(ctx, fmt.Sprintf("%s-cluster-role", name), &iam.RoleArgs{
		AssumeRolePolicy: pulumi.String(`{
			"Version": "2012-10-17",
			"Statement": [{
				"Effect": "Allow",
				"Principal": {"Service": "eks.amazonaws.com"},
				"Action": "sts:AssumeRole"
			}]
		}`),
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	clusterPolicyAttachment, err := iam.NewRolePolicyAttachment(ctx, fmt.Sprintf("%s-cluster-policy", name), &iam.RolePolicyAttachmentArgs{
		Role:      clusterRole.Name,
		PolicyArn: pulumi.String("arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"),
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Node IAM Role
	nodeRole, err := iam.NewRole(ctx, fmt.Sprintf("%s-node-role", name), &iam.RoleArgs{
		AssumeRolePolicy: pulumi.String(`{
			"Version": "2012-10-17",
			"Statement": [{
				"Effect": "Allow",
				"Principal": {"Service": "ec2.amazonaws.com"},
				"Action": "sts:AssumeRole"
			}]
		}`),
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	nodePolicyAttachments := []pulumi.Resource{}
	for i, policy := range []string{
		"arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
		"arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
		"arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
	} {
		attachment, err := iam.NewRolePolicyAttachment(ctx, fmt.Sprintf("%s-node-policy-%d", name, i), &iam.RolePolicyAttachmentArgs{
			Role:      nodeRole.Name,
			PolicyArn: pulumi.String(policy),
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
		nodePolicyAttachments = append(nodePolicyAttachments, attachment)
	}

	// EKS Cluster. The control plane must not be created before its policy
	// attachment exists, or cluster creation fails with a permissions error.
	cluster, err := eks.NewCluster(ctx, fmt.Sprintf("%s-cluster", name), &eks.ClusterArgs{
		Name:    args.ClusterName,
		Version: k8sVersion,
		RoleArn: clusterRole.Arn,
		VpcConfig: &eks.ClusterVpcConfigArgs{
			SubnetIds:             args.PrivateSubnetIDs,
			EndpointPublicAccess:  pulumi.Bool(true),
			EndpointPrivateAccess: pulumi.Bool(true),
		},
		EnabledClusterLogTypes: pulumi.StringArray{
			pulumi.String("api"),
			pulumi.String("audit"),
			pulumi.String("authenticator"),
		},
		Tags: tags,
	}, append(resourceOpts, pulumi.DependsOn([]pulumi.Resource{clusterPolicyAttachment}))...)
	if err != nil {
		return nil, err
	}

	// Managed Node Group. Nodes must not launch before they can join the
	// cluster, so wait for every policy attachment.
	nodeGroup, err := eks.NewNodeGroup(ctx, fmt.Sprintf("%s-nodegroup", name), &eks.NodeGroupArgs{
		ClusterName:   cluster.Name,
		NodeRoleArn:   nodeRole.Arn,
		SubnetIds:     args.PrivateSubnetIDs,
		InstanceTypes: pulumi.StringArray{nodeType},
		ScalingConfig: &eks.NodeGroupScalingConfigArgs{
			DesiredSize: desiredSize,
			MinSize:     minSize,
			MaxSize:     maxSize,
		},
		UpdateConfig: &eks.NodeGroupUpdateConfigArgs{
			MaxUnavailable: pulumi.Int(1),
		},
		Tags: tags,
	}, append(resourceOpts, pulumi.DependsOn(nodePolicyAttachments))...)
	if err != nil {
		return nil, err
	}

	component.ClusterName = cluster.Name
	component.ClusterEndpoint = cluster.Endpoint
	component.ClusterARN = cluster.Arn
	component.OIDCProviderURL = cluster.Identities.Index(pulumi.Int(0)).Oidcs().Index(pulumi.Int(0)).Issuer().Elem()
	component.NodeGroupARN = nodeGroup.Arn
	component.ClusterCaCertificate = cluster.CertificateAuthority.Data().Elem()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"clusterName":          component.ClusterName,
		"clusterEndpoint":      component.ClusterEndpoint,
		"clusterArn":           component.ClusterARN,
		"oidcProviderUrl":      component.OIDCProviderURL,
		"nodeGroupArn":         component.NodeGroupARN,
		"clusterCaCertificate": component.ClusterCaCertificate,
	})

	return component, nil
}
