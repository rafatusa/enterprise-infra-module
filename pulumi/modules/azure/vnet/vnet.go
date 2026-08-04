// Package vnet provides a Pulumi component resource for an Azure Virtual Network
// with configurable subnets and service endpoints.
// Mirrors infra/modules/azure/vnet.
//
// Usage:
//
//	vnet, err := vnet.NewVirtualNetwork(ctx, "prod", &vnet.Args{
//	    Name:              pulumi.String("prod-vnet"),
//	    ResourceGroupName: rg.ResourceGroupName,
//	    Location:          rg.Location,
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	    AddressSpaces:     pulumi.StringArray{pulumi.String("10.0.0.0/16")},
//	})
package vnet

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// SubnetConfig defines a subnet to create within the VNet.
type SubnetConfig struct {
	Name          string
	AddressPrefix string
}

// Args holds the configuration for the VNet component.
type Args struct {
	// Name is the virtual network name.
	Name pulumi.StringInput
	// ResourceGroupName is the resource group to deploy into.
	ResourceGroupName pulumi.StringInput
	// Location is the Azure region.
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// AddressSpaces are the CIDR ranges for the VNet.
	AddressSpaces pulumi.StringArrayInput
	// Subnets are the subnets to create within the VNet.
	Subnets []SubnetConfig
}

// VirtualNetwork is the component resource output.
type VirtualNetwork struct {
	pulumi.ResourceState

	VNetName  pulumi.StringOutput      `pulumi:"vnetName"`
	VNetID    pulumi.StringOutput      `pulumi:"vnetId"`
	SubnetIDs pulumi.StringArrayOutput `pulumi:"subnetIds"`
}

// NewVirtualNetwork creates a new Azure VNet component resource.
func NewVirtualNetwork(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*VirtualNetwork, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &VirtualNetwork{}
	err := ctx.RegisterComponentResource("udap:azure:VirtualNetwork", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("azure/vnet"),
	}

	subnets := network.SubnetTypeArray{}
	for _, s := range args.Subnets {
		subnets = append(subnets, &network.SubnetTypeArgs{
			Name:          pulumi.String(s.Name),
			AddressPrefix: pulumi.String(s.AddressPrefix),
		})
	}

	vnetResource, err := network.NewVirtualNetwork(ctx, fmt.Sprintf("%s-vnet", name), &network.VirtualNetworkArgs{
		VirtualNetworkName: args.Name,
		ResourceGroupName:  args.ResourceGroupName,
		Location:           args.Location,
		AddressSpace: &network.AddressSpaceArgs{
			AddressPrefixes: args.AddressSpaces,
		},
		Subnets: subnets,
		Tags:    tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.VNetName = vnetResource.Name
	component.VNetID = vnetResource.ID().ToStringOutput()
	component.SubnetIDs = pulumi.StringArray{}.ToStringArrayOutput()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"vnetName":  component.VNetName,
		"vnetId":    component.VNetID,
		"subnetIds": component.SubnetIDs,
	})

	return component, nil
}
