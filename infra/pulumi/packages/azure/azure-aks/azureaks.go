// Package azureaks is a Pulumi solution package that provisions a complete
// production-grade Azure AKS environment by composing all azure/* modules:
// resource-group + vnet + nsg + managed-identity + log-analytics + aks.
//
// Equivalent to infra/terraform/packages/azure/azure-aks but implemented as a
// Pulumi Go component.
//
// Usage:
//
//	env, err := azureaks.NewEnvironment(ctx, "prod", &azureaks.Args{
//	    ClusterName: pulumi.String("prod-aks"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	    Location:    pulumi.String("eastus"),
//	})
package azureaks

import (
	"fmt"

	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"

	"github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/aks"
	loganalytics "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/log-analytics"
	managedidentity "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/managed-identity"
	"github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/nsg"
	resourcegroup "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/resource-group"
	"github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/azure/vnet"
)

// Args holds the top-level configuration for the full AKS environment.
type Args struct {
	// ClusterName is the AKS cluster name.
	ClusterName pulumi.StringInput
	// Project is used for all resource naming and tagging.
	Project pulumi.StringInput
	// Environment tag value (e.g. production, staging).
	Environment pulumi.StringInput
	// Location is the Azure region. Default: eastus.
	Location pulumi.StringInput
	// KubernetesVersion pins the AKS version. Default: 1.30.
	KubernetesVersion pulumi.StringInput
	// SystemNodeCount is the system pool size. Default: 2.
	SystemNodeCount pulumi.IntInput
	// SystemVMSize is the system pool VM size. Default: Standard_D4s_v5.
	SystemVMSize pulumi.StringInput
}

// Environment is the full AKS environment component output.
type Environment struct {
	pulumi.ResourceState

	ResourceGroupName   pulumi.StringOutput `pulumi:"resourceGroupName"`
	VNetName            pulumi.StringOutput `pulumi:"vnetName"`
	ClusterName         pulumi.StringOutput `pulumi:"clusterName"`
	ClusterID           pulumi.StringOutput `pulumi:"clusterId"`
	IdentityPrincipalID pulumi.StringOutput `pulumi:"identityPrincipalId"`
	WorkspaceName       pulumi.StringOutput `pulumi:"workspaceName"`
}

// NewEnvironment provisions a complete Azure AKS environment.
func NewEnvironment(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Environment, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Environment{}
	err := ctx.RegisterComponentResource("udap:packages:AzureAks", name, component, opts...)
	if err != nil {
		return nil, err
	}

	parentOpt := pulumi.Parent(component)

	location := pulumi.String("eastus")
	if args.Location != nil {
		location = args.Location.(pulumi.String)
	}

	// 1. Resource Group
	rgComp, err := resourcegroup.NewResourceGroup(ctx, fmt.Sprintf("%s-rg", name), &resourcegroup.Args{
		Name:        pulumi.Sprintf("%s-rg", args.ClusterName),
		Location:    location,
		Project:     args.Project,
		Environment: args.Environment,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 2. VNet with system and user subnets
	vnetComp, err := vnet.NewVirtualNetwork(ctx, fmt.Sprintf("%s-vnet", name), &vnet.Args{
		Name:              pulumi.Sprintf("%s-vnet", args.ClusterName),
		ResourceGroupName: rgComp.ResourceGroupName,
		Location:          rgComp.Location,
		Project:           args.Project,
		Environment:       args.Environment,
		AddressSpaces:     pulumi.StringArray{pulumi.String("10.0.0.0/16")},
		Subnets: []vnet.SubnetConfig{
			{Name: "system", AddressPrefix: "10.0.1.0/24"},
			{Name: "user", AddressPrefix: "10.0.2.0/24"},
		},
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 3. NSG for AKS subnets
	_, err = nsg.NewNetworkSecurityGroup(ctx, fmt.Sprintf("%s-nsg", name), &nsg.Args{
		Name:              pulumi.Sprintf("%s-nsg", args.ClusterName),
		ResourceGroupName: rgComp.ResourceGroupName,
		Location:          rgComp.Location,
		Project:           args.Project,
		Environment:       args.Environment,
		SecurityRules: []nsg.SecurityRule{
			{
				Name:                     "allow-https",
				Priority:                 100,
				Direction:                "Inbound",
				Access:                   "Allow",
				Protocol:                 "Tcp",
				SourcePortRange:          "*",
				DestinationPortRange:     "443",
				SourceAddressPrefix:      "*",
				DestinationAddressPrefix: "*",
				Description:              "Allow HTTPS inbound",
			},
		},
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 4. Managed Identity for AKS
	miComp, err := managedidentity.NewManagedIdentity(ctx, fmt.Sprintf("%s-identity", name), &managedidentity.Args{
		Name:              pulumi.Sprintf("%s-identity", args.ClusterName),
		ResourceGroupName: rgComp.ResourceGroupName,
		Location:          rgComp.Location,
		Project:           args.Project,
		Environment:       args.Environment,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 5. Log Analytics Workspace
	laComp, err := loganalytics.NewWorkspace(ctx, fmt.Sprintf("%s-logs", name), &loganalytics.Args{
		Name:              pulumi.Sprintf("%s-logs", args.ClusterName),
		ResourceGroupName: rgComp.ResourceGroupName,
		Location:          rgComp.Location,
		Project:           args.Project,
		Environment:       args.Environment,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	// 6. AKS Cluster
	aksComp, err := aks.NewCluster(ctx, fmt.Sprintf("%s-aks", name), &aks.Args{
		ClusterName:       args.ClusterName,
		ResourceGroupName: rgComp.ResourceGroupName,
		Location:          rgComp.Location,
		Project:           args.Project,
		Environment:       args.Environment,
		SubnetID:          vnetComp.SubnetIDs.Index(pulumi.Int(0)),
		WorkspaceID:       laComp.WorkspaceID,
		KubernetesVersion: args.KubernetesVersion,
		SystemNodeCount:   args.SystemNodeCount,
		SystemVMSize:      args.SystemVMSize,
	}, parentOpt)
	if err != nil {
		return nil, err
	}

	component.ResourceGroupName = rgComp.ResourceGroupName
	component.VNetName = vnetComp.VNetName
	component.ClusterName = aksComp.ClusterName
	component.ClusterID = aksComp.ClusterID
	component.IdentityPrincipalID = miComp.PrincipalID
	component.WorkspaceName = laComp.WorkspaceName

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"resourceGroupName":   component.ResourceGroupName,
		"vnetName":            component.VNetName,
		"clusterName":         component.ClusterName,
		"clusterId":           component.ClusterID,
		"identityPrincipalId": component.IdentityPrincipalID,
		"workspaceName":       component.WorkspaceName,
	})

	return component, nil
}
