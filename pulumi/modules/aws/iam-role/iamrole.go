// Package iamrole provides a Pulumi component resource for an AWS IAM Role
// with trust policy, managed policy attachments, and optional instance profile.
// Mirrors infra/modules/aws/iam-role.
//
// Usage:
//
//	role, err := iamrole.NewRole(ctx, "app", &iamrole.Args{
//	    Name:              pulumi.String("app-role"),
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	    AssumeRoleService: pulumi.String("ec2.amazonaws.com"),
//	    ManagedPolicyARNs: pulumi.StringArray{
//	        pulumi.String("arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"),
//	    },
//	    CreateInstanceProfile: pulumi.Bool(true),
//	})
package iamrole

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/iam"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the IAM Role component.
type Args struct {
	// Name is the IAM role name.
	Name pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// AssumeRoleService is the AWS service principal (e.g. "ec2.amazonaws.com").
	AssumeRoleService pulumi.StringInput
	// AssumeRolePolicy overrides the generated trust policy JSON.
	AssumeRolePolicy pulumi.StringInput
	// ManagedPolicyARNs are AWS-managed or customer-managed policies to attach.
	ManagedPolicyARNs pulumi.StringArrayInput
	// InlinePolicy is an optional inline policy JSON string.
	InlinePolicy pulumi.StringInput
	// CreateInstanceProfile creates an EC2 instance profile. Default: false.
	CreateInstanceProfile pulumi.BoolInput
}

// Role is the component resource output.
type Role struct {
	pulumi.ResourceState

	RoleARN             pulumi.StringOutput `pulumi:"roleArn"`
	RoleName            pulumi.StringOutput `pulumi:"roleName"`
	InstanceProfileARN  pulumi.StringOutput `pulumi:"instanceProfileArn"`
	InstanceProfileName pulumi.StringOutput `pulumi:"instanceProfileName"`
}

// NewRole creates a new IAM Role component resource.
func NewRole(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Role, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Role{}
	err := ctx.RegisterComponentResource("udap:aws:IamRole", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/iam-role"),
	}

	var trustPolicy pulumi.StringInput
	if args.AssumeRolePolicy != nil {
		trustPolicy = args.AssumeRolePolicy
	} else {
		trustPolicy = args.AssumeRoleService.ToStringOutput().ApplyT(func(svc string) string {
			return fmt.Sprintf(`{
				"Version": "2012-10-17",
				"Statement": [{
					"Effect": "Allow",
					"Principal": {"Service": "%s"},
					"Action": "sts:AssumeRole"
				}]
			}`, svc)
		}).(pulumi.StringOutput)
	}

	role, err := iam.NewRole(ctx, fmt.Sprintf("%s-role", name), &iam.RoleArgs{
		Name:             args.Name,
		AssumeRolePolicy: trustPolicy,
		Tags:             tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Attach managed policies
	if args.ManagedPolicyARNs != nil {
		arns := args.ManagedPolicyARNs.ToStringArrayOutput()
		arns.ApplyT(func(policies []string) error {
			for i, arn := range policies {
				_, err := iam.NewRolePolicyAttachment(ctx,
					fmt.Sprintf("%s-policy-%d", name, i),
					&iam.RolePolicyAttachmentArgs{
						Role:      role.Name,
						PolicyArn: pulumi.String(arn),
					}, resourceOpts...)
				if err != nil {
					return err
				}
			}
			return nil
		})
	}

	// Instance Profile (optional)
	profile, err := iam.NewInstanceProfile(ctx, fmt.Sprintf("%s-profile", name), &iam.InstanceProfileArgs{
		Name: args.Name,
		Role: role.Name,
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.RoleARN = role.Arn
	component.RoleName = role.Name
	component.InstanceProfileARN = profile.Arn
	component.InstanceProfileName = profile.Name

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"roleArn":             component.RoleARN,
		"roleName":            component.RoleName,
		"instanceProfileArn":  component.InstanceProfileARN,
		"instanceProfileName": component.InstanceProfileName,
	})

	return component, nil
}
