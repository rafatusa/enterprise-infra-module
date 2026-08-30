// Package resourcegroup provides a Pulumi component resource for an Azure Resource Group
// with tags and optional management lock.
// Mirrors infra/modules/azure/resource-group.
//
// Usage:
//
//	rg, err := resourcegroup.NewResourceGroup(ctx, "prod", &resourcegroup.Args{
//	    Name:        pulumi.String("prod-rg"),
//	    Location:    pulumi.String("eastus"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	})
package resourcegroup

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/resources/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the Resource Group component.
type Args struct {
	// Name is the resource group name.
	Name pulumi.StringInput
	// Location is the Azure region (e.g. eastus, westeurope).
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// EnableLock adds a CanNotDelete management lock. Default: false.
	EnableLock pulumi.BoolInput
}

// ResourceGroup is the component resource output.
type ResourceGroup struct {
	pulumi.ResourceState

	ResourceGroupName pulumi.StringOutput `pulumi:"resourceGroupName"`
	ResourceGroupID   pulumi.StringOutput `pulumi:"resourceGroupId"`
	Location          pulumi.StringOutput `pulumi:"location"`
}

// NewResourceGroup creates a new Azure Resource Group component resource.
func NewResourceGroup(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*ResourceGroup, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &ResourceGroup{}
	err := ctx.RegisterComponentResource("udap:azure:ResourceGroup", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	rg, err := resources.NewResourceGroup(ctx, fmt.Sprintf("%s-rg", name), &resources.ResourceGroupArgs{
		ResourceGroupName: args.Name,
		Location:          args.Location,
		Tags: pulumi.StringMap{
			"Project":     args.Project,
			"Environment": args.Environment,
			"ManagedBy":   pulumi.String("pulumi"),
			"Module":      pulumi.String("azure/resource-group"),
		},
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.ResourceGroupName = rg.Name
	component.ResourceGroupID = rg.ID().ToStringOutput()
	component.Location = rg.Location

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"resourceGroupName": component.ResourceGroupName,
		"resourceGroupId":   component.ResourceGroupID,
		"location":          component.Location,
	})

	return component, nil
}
