// Package iamrole provides a Pulumi component resource for an AWS IAM Role
// with trust policy, managed policy attachments, and optional instance profile.
// Mirrors infra/terraform/modules/aws/iam-role.
//
// Usage:
//
//	role, err := iamrole.NewRole(ctx, "app", &iamrole.Args{
//	    Name:              pulumi.String("app-role"),
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	    AssumeRoleService: pulumi.String("ec2.amazonaws.com"),
//	    ManagedPolicyARNs: []string{
//	        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
//	    },
//	    CreateInstanceProfile: true,
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
	// Ignored when AssumeRolePolicy is set. Defaults to ec2.amazonaws.com.
	AssumeRoleService pulumi.StringInput
	// AssumeRolePolicy overrides the generated trust policy JSON.
	AssumeRolePolicy pulumi.StringInput
	// ManagedPolicyARNs are AWS-managed or customer-managed policies to attach.
	// This is a plain slice, not an Input: the number of attachments must be
	// known at construction time so each one is a real, addressable resource.
	ManagedPolicyARNs []string
	// InlinePolicy is an optional inline policy JSON string.
	InlinePolicy pulumi.StringInput
	// CreateInstanceProfile creates an EC2 instance profile. Default: false.
	CreateInstanceProfile bool
}

// Role is the component resource output.
type Role struct {
	pulumi.ResourceState

	RoleARN  pulumi.StringOutput `pulumi:"roleArn"`
	RoleName pulumi.StringOutput `pulumi:"roleName"`
	// InstanceProfileARN and InstanceProfileName are empty strings when
	// CreateInstanceProfile is false.
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
	switch {
	case args.AssumeRolePolicy != nil:
		trustPolicy = args.AssumeRolePolicy
	default:
		service := args.AssumeRoleService
		if service == nil {
			service = pulumi.String("ec2.amazonaws.com")
		}
		trustPolicy = service.ToStringOutput().ApplyT(func(svc string) string {
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

	// Attach managed policies. These are created synchronously so that
	// registration errors propagate to the caller — creating resources inside
	// an ApplyT callback races the engine and silently drops the error.
	for i, arn := range args.ManagedPolicyARNs {
		_, err := iam.NewRolePolicyAttachment(ctx,
			fmt.Sprintf("%s-policy-%d", name, i),
			&iam.RolePolicyAttachmentArgs{
				Role:      role.Name,
				PolicyArn: pulumi.String(arn),
			}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// Inline policy (optional)
	if args.InlinePolicy != nil {
		_, err = iam.NewRolePolicy(ctx, fmt.Sprintf("%s-inline", name), &iam.RolePolicyArgs{
			Role:   role.ID(),
			Policy: args.InlinePolicy,
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// Instance Profile (optional)
	component.RoleARN = role.Arn
	component.RoleName = role.Name

	if args.CreateInstanceProfile {
		profile, err := iam.NewInstanceProfile(ctx, fmt.Sprintf("%s-profile", name), &iam.InstanceProfileArgs{
			Name: args.Name,
			Role: role.Name,
			Tags: tags,
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
		component.InstanceProfileARN = profile.Arn
		component.InstanceProfileName = profile.Name
	} else {
		component.InstanceProfileARN = pulumi.String("").ToStringOutput()
		component.InstanceProfileName = pulumi.String("").ToStringOutput()
	}

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"roleArn":             component.RoleARN,
		"roleName":            component.RoleName,
		"instanceProfileArn":  component.InstanceProfileARN,
		"instanceProfileName": component.InstanceProfileName,
	})

	return component, nil
}
