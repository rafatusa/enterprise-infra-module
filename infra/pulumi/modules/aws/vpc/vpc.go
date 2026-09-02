// Package vpc provides a Pulumi component resource for an AWS VPC
// with public and private subnets, NAT Gateway, Internet Gateway,
// and route tables. Mirrors infra/terraform/modules/aws/vpc.
//
// Usage:
//
//	vpc, err := vpc.NewVpc(ctx, "prod", &vpc.Args{
//	    Name:               pulumi.String("prod"),
//	    Project:            pulumi.String("my-project"),
//	    Environment:        pulumi.String("production"),
//	    CidrBlock:          pulumi.String("10.0.0.0/16"),
//	    AvailabilityZones:  []string{"us-east-1a", "us-east-1b"},
//	    PublicSubnetCidrs:  []string{"10.0.1.0/24", "10.0.2.0/24"},
//	    PrivateSubnetCidrs: []string{"10.0.10.0/24", "10.0.11.0/24"},
//	})
//
// PublicSubnetIDs and PrivateSubnetIDs are ordered to match their
// corresponding CIDR slices.
package vpc

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/ec2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the VPC component.
//
// The AZ and CIDR lists are plain slices rather than pulumi Inputs because
// they determine how many subnet resources are created, which must be known
// at construction time.
type Args struct {
	// Name is the base name for all VPC resources.
	Name pulumi.StringInput
	// Project is used for tagging and naming.
	Project pulumi.StringInput
	// Environment tag value (e.g. production, staging).
	Environment pulumi.StringInput
	// CidrBlock is the VPC CIDR range. Default: 10.0.0.0/16.
	CidrBlock pulumi.StringInput
	// AvailabilityZones lists the AZs to deploy subnets into. Subnets are
	// distributed across them round-robin.
	AvailabilityZones []string
	// PublicSubnetCidrs lists CIDR blocks for public subnets (one per AZ).
	PublicSubnetCidrs []string
	// PrivateSubnetCidrs lists CIDR blocks for private subnets (one per AZ).
	PrivateSubnetCidrs []string
	// EnableNatGateway controls whether a NAT Gateway is created for the
	// private subnets. Default: true.
	EnableNatGateway *bool
}

// Vpc is the component resource output.
type Vpc struct {
	pulumi.ResourceState

	VpcID             pulumi.StringOutput      `pulumi:"vpcId"`
	PublicSubnetIDs   pulumi.StringArrayOutput `pulumi:"publicSubnetIds"`
	PrivateSubnetIDs  pulumi.StringArrayOutput `pulumi:"privateSubnetIds"`
	InternetGatewayID pulumi.StringOutput      `pulumi:"internetGatewayId"`
	// NatGatewayID is an empty string when no NAT Gateway was created.
	NatGatewayID pulumi.StringOutput `pulumi:"natGatewayId"`
}

// NewVpc creates a new VPC component resource.
func NewVpc(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Vpc, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}
	if len(args.AvailabilityZones) == 0 {
		return nil, fmt.Errorf("at least one availability zone is required")
	}

	component := &Vpc{}
	err := ctx.RegisterComponentResource("udap:aws:Vpc", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	// Never type-assert a pulumi Input to a concrete type — callers
	// legitimately pass Outputs from other resources, which would panic.
	cidr := args.CidrBlock
	if cidr == nil {
		cidr = pulumi.String("10.0.0.0/16")
	}

	enableNat := args.EnableNatGateway == nil || *args.EnableNatGateway

	commonTags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/vpc"),
	}

	// VPC
	vpcResource, err := ec2.NewVpc(ctx, fmt.Sprintf("%s-vpc", name), &ec2.VpcArgs{
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
		VpcId: vpcResource.ID(),
		Tags: pulumi.StringMap{
			"Name":      pulumi.Sprintf("%s-igw", args.Name),
			"Project":   args.Project,
			"ManagedBy": pulumi.String("pulumi"),
		},
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Public subnets
	publicSubnets := make([]*ec2.Subnet, 0, len(args.PublicSubnetCidrs))
	publicSubnetIDs := pulumi.StringArray{}
	for i, subnetCidr := range args.PublicSubnetCidrs {
		az := args.AvailabilityZones[i%len(args.AvailabilityZones)]
		subnet, err := ec2.NewSubnet(ctx, fmt.Sprintf("%s-public-%d", name, i+1), &ec2.SubnetArgs{
			VpcId:               vpcResource.ID(),
			CidrBlock:           pulumi.String(subnetCidr),
			AvailabilityZone:    pulumi.String(az),
			MapPublicIpOnLaunch: pulumi.Bool(true),
			Tags: pulumi.StringMap{
				"Name":        pulumi.Sprintf("%s-public-%d", args.Name, i+1),
				"Project":     args.Project,
				"Environment": args.Environment,
				"ManagedBy":   pulumi.String("pulumi"),
				"Tier":        pulumi.String("public"),
			},
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
		publicSubnets = append(publicSubnets, subnet)
		publicSubnetIDs = append(publicSubnetIDs, subnet.ID().ToStringOutput())
	}

	// Private subnets
	privateSubnets := make([]*ec2.Subnet, 0, len(args.PrivateSubnetCidrs))
	privateSubnetIDs := pulumi.StringArray{}
	for i, subnetCidr := range args.PrivateSubnetCidrs {
		az := args.AvailabilityZones[i%len(args.AvailabilityZones)]
		subnet, err := ec2.NewSubnet(ctx, fmt.Sprintf("%s-private-%d", name, i+1), &ec2.SubnetArgs{
			VpcId:            vpcResource.ID(),
			CidrBlock:        pulumi.String(subnetCidr),
			AvailabilityZone: pulumi.String(az),
			Tags: pulumi.StringMap{
				"Name":        pulumi.Sprintf("%s-private-%d", args.Name, i+1),
				"Project":     args.Project,
				"Environment": args.Environment,
				"ManagedBy":   pulumi.String("pulumi"),
				"Tier":        pulumi.String("private"),
			},
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
		privateSubnets = append(privateSubnets, subnet)
		privateSubnetIDs = append(privateSubnetIDs, subnet.ID().ToStringOutput())
	}

	// Public route table: default route via the Internet Gateway.
	publicRT, err := ec2.NewRouteTable(ctx, fmt.Sprintf("%s-public-rt", name), &ec2.RouteTableArgs{
		VpcId: vpcResource.ID(),
		Routes: ec2.RouteTableRouteArray{
			&ec2.RouteTableRouteArgs{
				CidrBlock: pulumi.String("0.0.0.0/0"),
				GatewayId: igw.ID(),
			},
		},
		Tags: commonTags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	for i, subnet := range publicSubnets {
		_, err = ec2.NewRouteTableAssociation(ctx, fmt.Sprintf("%s-public-rta-%d", name, i+1), &ec2.RouteTableAssociationArgs{
			SubnetId:     subnet.ID(),
			RouteTableId: publicRT.ID(),
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// NAT Gateway and private routing (optional).
	component.NatGatewayID = pulumi.String("").ToStringOutput()
	if enableNat && len(publicSubnets) > 0 && len(privateSubnets) > 0 {
		eip, err := ec2.NewEip(ctx, fmt.Sprintf("%s-nat-eip", name), &ec2.EipArgs{
			Domain: pulumi.String("vpc"),
			Tags:   commonTags,
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}

		natGW, err := ec2.NewNatGateway(ctx, fmt.Sprintf("%s-nat", name), &ec2.NatGatewayArgs{
			AllocationId: eip.ID(),
			SubnetId:     publicSubnets[0].ID(),
			Tags:         commonTags,
		}, append(resourceOpts, pulumi.DependsOn([]pulumi.Resource{igw}))...)
		if err != nil {
			return nil, err
		}

		privateRT, err := ec2.NewRouteTable(ctx, fmt.Sprintf("%s-private-rt", name), &ec2.RouteTableArgs{
			VpcId: vpcResource.ID(),
			Routes: ec2.RouteTableRouteArray{
				&ec2.RouteTableRouteArgs{
					CidrBlock:    pulumi.String("0.0.0.0/0"),
					NatGatewayId: natGW.ID(),
				},
			},
			Tags: commonTags,
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}

		for i, subnet := range privateSubnets {
			_, err = ec2.NewRouteTableAssociation(ctx, fmt.Sprintf("%s-private-rta-%d", name, i+1), &ec2.RouteTableAssociationArgs{
				SubnetId:     subnet.ID(),
				RouteTableId: privateRT.ID(),
			}, resourceOpts...)
			if err != nil {
				return nil, err
			}
		}

		component.NatGatewayID = natGW.ID().ToStringOutput()
	}

	component.VpcID = vpcResource.ID().ToStringOutput()
	component.InternetGatewayID = igw.ID().ToStringOutput()
	component.PublicSubnetIDs = publicSubnetIDs.ToStringArrayOutput()
	component.PrivateSubnetIDs = privateSubnetIDs.ToStringArrayOutput()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"vpcId":             component.VpcID,
		"internetGatewayId": component.InternetGatewayID,
		"publicSubnetIds":   component.PublicSubnetIDs,
		"privateSubnetIds":  component.PrivateSubnetIDs,
		"natGatewayId":      component.NatGatewayID,
	})

	return component, nil
}
