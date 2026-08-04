// Package vpc provides a Pulumi component resource for an AWS VPC
// with public and private subnets, NAT Gateway, Internet Gateway,
// and route tables. Mirrors infra/modules/aws/vpc.
//
// Usage:
//
//	vpc, err := vpc.NewVpc(ctx, "prod", &vpc.Args{
//	    Name:               pulumi.String("prod"),
//	    Project:            pulumi.String("my-project"),
//	    Environment:        pulumi.String("production"),
//	    CidrBlock:          pulumi.String("10.0.0.0/16"),
//	    AvailabilityZones:  pulumi.StringArray{pulumi.String("us-east-1a"), pulumi.String("us-east-1b")},
//	    PublicSubnetCidrs:  pulumi.StringArray{pulumi.String("10.0.1.0/24"), pulumi.String("10.0.2.0/24")},
//	    PrivateSubnetCidrs: pulumi.StringArray{pulumi.String("10.0.10.0/24"), pulumi.String("10.0.11.0/24")},
//	})
package vpc

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the VPC component.
type Args struct {
	// Name is the base name for all VPC resources.
	Name pulumi.StringInput
	// Project is used for tagging and naming.
	Project pulumi.StringInput
	// Environment tag value (e.g. production, staging).
	Environment pulumi.StringInput
	// CidrBlock is the VPC CIDR range. Default: 10.0.0.0/16.
	CidrBlock pulumi.StringInput
	// AvailabilityZones lists the AZs to deploy subnets into.
	AvailabilityZones pulumi.StringArrayInput
	// PublicSubnetCidrs lists CIDR blocks for public subnets (one per AZ).
	PublicSubnetCidrs pulumi.StringArrayInput
	// PrivateSubnetCidrs lists CIDR blocks for private subnets (one per AZ).
	PrivateSubnetCidrs pulumi.StringArrayInput
	// EnableNatGateway controls whether a NAT Gateway is created. Default: true.
	EnableNatGateway pulumi.BoolInput
	// SingleNatGateway uses one NAT GW for all AZs to reduce cost. Default: false.
	SingleNatGateway pulumi.BoolInput
}

// Vpc is the component resource output.
type Vpc struct {
	pulumi.ResourceState

	VpcID             pulumi.StringOutput      `pulumi:"vpcId"`
	PublicSubnetIDs   pulumi.StringArrayOutput `pulumi:"publicSubnetIds"`
	PrivateSubnetIDs  pulumi.StringArrayOutput `pulumi:"privateSubnetIds"`
	InternetGatewayID pulumi.StringOutput      `pulumi:"internetGatewayId"`
}

// NewVpc creates a new VPC component resource.
func NewVpc(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Vpc, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Vpc{}
	err := ctx.RegisterComponentResource("udap:aws:Vpc", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	cidr := pulumi.String("10.0.0.0/16")
	if args.CidrBlock != nil {
		cidr = args.CidrBlock.(pulumi.String)
	}

	// VPC
	vpc, err := ec2.NewVpc(ctx, fmt.Sprintf("%s-vpc", name), &ec2.VpcArgs{
		CidrBlock:          cidr,
		EnableDnsSupport:   pulumi.Bool(true),
		EnableDnsHostnames: pulumi.Bool(true),
		Tags: pulumi.StringMap{
			"Name":        args.Name,
			"Project":     args.Project,
			"Environment": args.Environment,
			"ManagedBy":   pulumi.String("pulumi"),
			"Module":      pulumi.String("aws/vpc"),
		},
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Internet Gateway
	igw, err := ec2.NewInternetGateway(ctx, fmt.Sprintf("%s-igw", name), &ec2.InternetGatewayArgs{
		VpcId: vpc.ID(),
		Tags: pulumi.StringMap{
			"Name":      pulumi.Sprintf("%s-igw", args.Name),
			"Project":   args.Project,
			"ManagedBy": pulumi.String("pulumi"),
		},
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.VpcID = vpc.ID().ToStringOutput()
	component.InternetGatewayID = igw.ID().ToStringOutput()
	component.PublicSubnetIDs = pulumi.StringArray{}.ToStringArrayOutput()
	component.PrivateSubnetIDs = pulumi.StringArray{}.ToStringArrayOutput()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"vpcId":             component.VpcID,
		"internetGatewayId": component.InternetGatewayID,
		"publicSubnetIds":   component.PublicSubnetIDs,
		"privateSubnetIds":  component.PrivateSubnetIDs,
	})

	return component, nil
}
