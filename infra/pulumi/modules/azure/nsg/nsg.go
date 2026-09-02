// Package nsg provides a Pulumi component resource for an Azure Network Security Group
// with configurable security rules.
// Mirrors infra/terraform/modules/azure/nsg.
//
// Usage:
//
//	nsg, err := nsg.NewNetworkSecurityGroup(ctx, "web", &nsg.Args{
//	    Name:              pulumi.String("web-nsg"),
//	    ResourceGroupName: rg.ResourceGroupName,
//	    Location:          rg.Location,
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	})
package nsg

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/network/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// SecurityRule defines a single NSG security rule.
type SecurityRule struct {
	Name                     string
	Priority                 int
	Direction                string // Inbound | Outbound
	Access                   string // Allow | Deny
	Protocol                 string // Tcp | Udp | *
	SourcePortRange          string
	DestinationPortRange     string
	SourceAddressPrefix      string
	DestinationAddressPrefix string
	Description              string
}

// Args holds the configuration for the NSG component.
type Args struct {
	// Name is the NSG name.
	Name pulumi.StringInput
	// ResourceGroupName is the resource group to deploy into.
	ResourceGroupName pulumi.StringInput
	// Location is the Azure region.
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// SecurityRules are the NSG rules to create. An empty slice leaves the
	// Azure platform default rules in place.
	SecurityRules []SecurityRule
}

// NetworkSecurityGroup is the component resource output.
type NetworkSecurityGroup struct {
	pulumi.ResourceState

	NSGName pulumi.StringOutput `pulumi:"nsgName"`
	NSGID   pulumi.StringOutput `pulumi:"nsgId"`
}

// NewNetworkSecurityGroup creates a new Azure NSG component resource.
func NewNetworkSecurityGroup(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*NetworkSecurityGroup, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &NetworkSecurityGroup{}
	err := ctx.RegisterComponentResource("udap:azure:NetworkSecurityGroup", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("azure/nsg"),
	}

	rules := network.SecurityRuleTypeArray{}
	for _, r := range args.SecurityRules {
		rules = append(rules, &network.SecurityRuleTypeArgs{
			Name:                     pulumi.String(r.Name),
			Priority:                 pulumi.Int(r.Priority),
			Direction:                pulumi.String(r.Direction),
			Access:                   pulumi.String(r.Access),
			Protocol:                 pulumi.String(r.Protocol),
			SourcePortRange:          pulumi.String(r.SourcePortRange),
			DestinationPortRange:     pulumi.String(r.DestinationPortRange),
			SourceAddressPrefix:      pulumi.String(r.SourceAddressPrefix),
			DestinationAddressPrefix: pulumi.String(r.DestinationAddressPrefix),
			Description:              pulumi.String(r.Description),
		})
	}

	nsgResource, err := network.NewNetworkSecurityGroup(ctx, fmt.Sprintf("%s-nsg", name), &network.NetworkSecurityGroupArgs{
		NetworkSecurityGroupName: args.Name,
		ResourceGroupName:        args.ResourceGroupName,
		Location:                 args.Location,
		SecurityRules:            rules,
		Tags:                     tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.NSGName = nsgResource.Name
	component.NSGID = nsgResource.ID().ToStringOutput()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"nsgName": component.NSGName,
		"nsgId":   component.NSGID,
	})

	return component, nil
}
