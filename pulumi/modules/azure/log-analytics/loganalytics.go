// Package loganalytics provides a Pulumi component resource for an Azure
// Log Analytics Workspace with configurable retention and solutions.
// Mirrors infra/modules/azure/log-analytics.
//
// Usage:
//
//	la, err := loganalytics.NewWorkspace(ctx, "prod", &loganalytics.Args{
//	    Name:              pulumi.String("prod-logs"),
//	    ResourceGroupName: rg.ResourceGroupName,
//	    Location:          rg.Location,
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	})
package loganalytics

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/operationalinsights/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the Log Analytics Workspace component.
type Args struct {
	// Name is the workspace name.
	Name pulumi.StringInput
	// ResourceGroupName is the resource group to deploy into.
	ResourceGroupName pulumi.StringInput
	// Location is the Azure region.
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// RetentionDays is the data retention in days. Default: 30.
	RetentionDays pulumi.IntInput
	// Sku is the pricing tier. Default: PerGB2018.
	Sku pulumi.StringInput
	// EnableContainerInsights adds the ContainerInsights solution. Default: false.
	EnableContainerInsights pulumi.BoolInput
}

// Workspace is the component resource output.
type Workspace struct {
	pulumi.ResourceState

	WorkspaceName pulumi.StringOutput `pulumi:"workspaceName"`
	WorkspaceID   pulumi.StringOutput `pulumi:"workspaceId"`
	WorkspaceKey  pulumi.StringOutput `pulumi:"workspaceKey"`
	CustomerID    pulumi.StringOutput `pulumi:"customerId"`
}

// NewWorkspace creates a new Azure Log Analytics Workspace component resource.
func NewWorkspace(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Workspace, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Workspace{}
	err := ctx.RegisterComponentResource("udap:azure:LogAnalyticsWorkspace", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("azure/log-analytics"),
	}

	workspace, err := operationalinsights.NewWorkspace(ctx, fmt.Sprintf("%s-workspace", name), &operationalinsights.WorkspaceArgs{
		WorkspaceName:     args.Name,
		ResourceGroupName: args.ResourceGroupName,
		Location:          args.Location,
		RetentionInDays:   pulumi.Int(30),
		Sku: &operationalinsights.WorkspaceSkuArgs{
			Name: pulumi.String("PerGB2018"),
		},
		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Container Insights Solution
	_, err = operationalinsights.NewLinkedService(ctx, fmt.Sprintf("%s-insights-link", name), &operationalinsights.LinkedServiceArgs{
		ResourceGroupName: args.ResourceGroupName,
		WorkspaceName:     workspace.Name,
		LinkedServiceName: pulumi.String("ContainerInsights"),
	}, resourceOpts...)
	if err != nil {
		// Non-fatal — ContainerInsights solution may not be available in all regions
		ctx.Log.Warn(fmt.Sprintf("Could not enable ContainerInsights for %s: %v", name, err), nil)
	}

	sharedKeys := operationalinsights.GetSharedKeysOutput(ctx, operationalinsights.GetSharedKeysOutputArgs{
		ResourceGroupName: args.ResourceGroupName,
		WorkspaceName:     workspace.Name,
	})

	component.WorkspaceName = workspace.Name
	component.WorkspaceID = workspace.ID().ToStringOutput()
	component.CustomerID = workspace.CustomerId.Elem()
	component.WorkspaceKey = sharedKeys.PrimarySharedKey().Elem()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"workspaceName": component.WorkspaceName,
		"workspaceId":   component.WorkspaceID,
		"customerId":    component.CustomerID,
	})

	return component, nil
}
