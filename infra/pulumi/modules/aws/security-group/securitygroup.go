// Package securitygroup provides a Pulumi component resource for an AWS Security Group
// with configurable ingress and egress rules.
// Mirrors infra/terraform/modules/aws/security-group.
//
// Usage:
//
//	sg, err := securitygroup.NewSecurityGroup(ctx, "web", &securitygroup.Args{
//	    Name:        pulumi.String("web-sg"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	    VpcID:       vpc.VpcID,
//	    IngressRules: []securitygroup.IngressRule{
//	        {FromPort: 80, ToPort: 80, Protocol: "tcp", CidrBlocks: []string{"0.0.0.0/0"}},
//	    },
//	})
package securitygroup

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// IngressRule defines a single ingress rule.
type IngressRule struct {
	FromPort    int
	ToPort      int
	Protocol    string
	CidrBlocks  []string
	Description string
}

// Args holds the configuration for the SecurityGroup component.
type Args struct {
	// Name is the security group name.
	Name pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// VpcID is the VPC the security group belongs to.
	VpcID pulumi.StringInput
	// Description defaults to "Managed by Pulumi" when nil.
	Description pulumi.StringInput
	// IngressRules are the inbound rules.
	IngressRules []IngressRule
	// AllowAllEgress adds a default allow-all egress rule. Default: true.
	// Set to pulumi.Bool(false) to create the group with no egress rules.
	AllowAllEgress *bool
}

// SecurityGroup is the component resource output.
type SecurityGroup struct {
	pulumi.ResourceState

	SecurityGroupID  pulumi.StringOutput `pulumi:"securityGroupId"`
	SecurityGroupARN pulumi.StringOutput `pulumi:"securityGroupArn"`
}

// NewSecurityGroup creates a new SecurityGroup component resource.
func NewSecurityGroup(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*SecurityGroup, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &SecurityGroup{}
	err := ctx.RegisterComponentResource("udap:aws:SecurityGroup", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Name":        args.Name,
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/security-group"),
	}

	ingress := ec2.SecurityGroupIngressArray{}
	for _, rule := range args.IngressRules {
		cidrs := make(pulumi.StringArray, len(rule.CidrBlocks))
		for i, c := range rule.CidrBlocks {
			cidrs[i] = pulumi.String(c)
		}
		ingress = append(ingress, &ec2.SecurityGroupIngressArgs{
			FromPort:    pulumi.Int(rule.FromPort),
			ToPort:      pulumi.Int(rule.ToPort),
			Protocol:    pulumi.String(rule.Protocol),
			CidrBlocks:  cidrs,
			Description: pulumi.String(rule.Description),
		})
	}

	// AllowAllEgress defaults to true when unset.
	allowAllEgress := args.AllowAllEgress == nil || *args.AllowAllEgress

	egress := ec2.SecurityGroupEgressArray{}
	if allowAllEgress {
		egress = append(egress, &ec2.SecurityGroupEgressArgs{
			FromPort:    pulumi.Int(0),
			ToPort:      pulumi.Int(0),
			Protocol:    pulumi.String("-1"),
			CidrBlocks:  pulumi.StringArray{pulumi.String("0.0.0.0/0")},
			Description: pulumi.String("Allow all outbound"),
		})
	}

	// Never type-assert a pulumi Input to a concrete type — callers
	// legitimately pass Outputs from other resources, which would panic.
	desc := args.Description
	if desc == nil {
		desc = pulumi.String("Managed by Pulumi")
	}

	sg, err := ec2.NewSecurityGroup(ctx, fmt.Sprintf("%s-sg", name), &ec2.SecurityGroupArgs{
		Name:        args.Name,
		VpcId:       args.VpcID,
		Description: desc,
		Ingress:     ingress,
		Egress:      egress,
		Tags:        tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.SecurityGroupID = sg.ID().ToStringOutput()
	component.SecurityGroupARN = sg.Arn

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"securityGroupId":  component.SecurityGroupID,
		"securityGroupArn": component.SecurityGroupARN,
	})

	return component, nil
}
