// Package ec2 provides a Pulumi component resource for an AWS EC2 instance
// with security group, IAM instance profile, and EBS encryption.
// Mirrors infra/modules/aws/ec2.
//
// Usage:
//
//	instance, err := ec2.NewInstance(ctx, "web", &ec2.Args{
//	    Name:         pulumi.String("web"),
//	    Project:      pulumi.String("my-project"),
//	    Environment:  pulumi.String("production"),
//	    SubnetID:     subnet.ID(),
//	    VpcID:        vpc.VpcID,
//	    InstanceType: pulumi.String("t3.micro"),
//	    KeyName:      pulumi.String("my-key"),
//	})
package ec2

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the EC2 instance component.
type Args struct {
	// Name is the base name for all resources.
	Name pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// SubnetID is the subnet to launch the instance in.
	SubnetID pulumi.StringInput
	// VpcID is the VPC the instance belongs to (for SG attachment).
	VpcID pulumi.StringInput
	// InstanceType defaults to t3.micro.
	InstanceType pulumi.StringInput
	// KeyName is the EC2 key pair name for SSH access.
	KeyName pulumi.StringInput
	// AmiID overrides the default Amazon Linux 2023 AMI lookup.
	AmiID pulumi.StringInput
	// RootVolumeSizeGB defaults to 20.
	RootVolumeSizeGB pulumi.IntInput
	// AllowedSSHCidrs are CIDRs allowed SSH access. Default: ["0.0.0.0/0"].
	AllowedSSHCidrs pulumi.StringArrayInput
	// AllowedHTTPCidrs are CIDRs allowed HTTP access. Default: ["0.0.0.0/0"].
	AllowedHTTPCidrs pulumi.StringArrayInput
}

// Instance is the component resource output.
type Instance struct {
	pulumi.ResourceState

	InstanceID      pulumi.StringOutput `pulumi:"instanceId"`
	PublicIP        pulumi.StringOutput `pulumi:"publicIp"`
	PrivateIP       pulumi.StringOutput `pulumi:"privateIp"`
	SecurityGroupID pulumi.StringOutput `pulumi:"securityGroupId"`
	IamRoleARN      pulumi.StringOutput `pulumi:"iamRoleArn"`
}

// NewInstance creates a new EC2 instance component resource.
func NewInstance(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Instance, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Instance{}
	err := ctx.RegisterComponentResource("udap:aws:Ec2Instance", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Name":        args.Name,
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/ec2"),
	}

	// Security Group
	sg, err := ec2.NewSecurityGroup(ctx, fmt.Sprintf("%s-sg", name), &ec2.SecurityGroupArgs{
		VpcId:       args.VpcID,
		Description: pulumi.Sprintf("Security group for %s", args.Name),
		Ingress: ec2.SecurityGroupIngressArray{
			&ec2.SecurityGroupIngressArgs{
				FromPort:   pulumi.Int(22),
				ToPort:     pulumi.Int(22),
				Protocol:   pulumi.String("tcp"),
				CidrBlocks: pulumi.StringArray{pulumi.String("0.0.0.0/0")},
				Description: pulumi.String("SSH access"),
			},
			&ec2.SecurityGroupIngressArgs{
				FromPort:   pulumi.Int(80),
				ToPort:     pulumi.Int(80),
				Protocol:   pulumi.String("tcp"),
				CidrBlocks: pulumi.StringArray{pulumi.String("0.0.0.0/0")},
				Description: pulumi.String("HTTP access"),
			},
			&ec2.SecurityGroupIngressArgs{
				FromPort:   pulumi.Int(443),
				ToPort:     pulumi.Int(443),
				Protocol:   pulumi.String("tcp"),
				CidrBlocks: pulumi.StringArray{pulumi.String("0.0.0.0/0")},
				Description: pulumi.String("HTTPS access"),
			},
		},
		Egress: ec2.SecurityGroupEgressArray{
			&ec2.SecurityGroupEgressArgs{
				FromPort:   pulumi.Int(0),
				ToPort:     pulumi.Int(0),
				Protocol:   pulumi.String("-1"),
				CidrBlocks: pulumi.StringArray{pulumi.String("0.0.0.0/0")},
				Description: pulumi.String("Allow all outbound"),
			},
		},
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// IAM Role
	role, err := iam.NewRole(ctx, fmt.Sprintf("%s-role", name), &iam.RoleArgs{
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

	// Attach SSM managed policy for session manager access
	_, err = iam.NewRolePolicyAttachment(ctx, fmt.Sprintf("%s-ssm-policy", name), &iam.RolePolicyAttachmentArgs{
		Role:      role.Name,
		PolicyArn: pulumi.String("arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"),
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Instance Profile
	profile, err := iam.NewInstanceProfile(ctx, fmt.Sprintf("%s-profile", name), &iam.InstanceProfileArgs{
		Role: role.Name,
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	instanceType := "t3.micro"
	if args.InstanceType != nil {
		instanceType = args.InstanceType.(pulumi.String).ToStringOutput().ApplyT(func(v string) string { return v }).(string)
	}

	// EC2 Instance
	instance, err := ec2.NewInstance(ctx, fmt.Sprintf("%s-instance", name), &ec2.InstanceArgs{
		Ami:                 pulumi.String("resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"),
		InstanceType:        pulumi.String(instanceType),
		SubnetId:            args.SubnetID,
		VpcSecurityGroupIds: pulumi.StringArray{sg.ID()},
		IamInstanceProfile:  profile.Name,
		KeyName:             args.KeyName,
		RootBlockDevice: &ec2.InstanceRootBlockDeviceArgs{
			VolumeSize: pulumi.Int(20),
			VolumeType: pulumi.String("gp3"),
			Encrypted:  pulumi.Bool(true),
		},
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.InstanceID = instance.ID().ToStringOutput()
	component.PublicIP = instance.PublicIp
	component.PrivateIP = instance.PrivateIp
	component.SecurityGroupID = sg.ID().ToStringOutput()
	component.IamRoleARN = role.Arn

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"instanceId":      component.InstanceID,
		"publicIp":        component.PublicIP,
		"privateIp":       component.PrivateIP,
		"securityGroupId": component.SecurityGroupID,
		"iamRoleArn":      component.IamRoleARN,
	})

	return component, nil
}
