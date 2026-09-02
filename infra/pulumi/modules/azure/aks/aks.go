// Package aks provides a Pulumi component resource for an Azure Kubernetes Service (AKS) cluster
// with system node pool, managed identity, RBAC, and Log Analytics integration.
// Mirrors infra/terraform/modules/azure/aks.
//
// Usage:
//
//	cluster, err := aks.NewCluster(ctx, "prod", &aks.Args{
//	    ClusterName:       pulumi.String("prod-aks"),
//	    ResourceGroupName: rg.ResourceGroupName,
//	    Location:          rg.Location,
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	    SubnetID:          vnet.SubnetIDs.Index(pulumi.Int(0)),
//	    WorkspaceID:       la.WorkspaceID,
//	})
package aks

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/containerservice/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the AKS cluster component.
type Args struct {
	// ClusterName is the AKS cluster name.
	ClusterName pulumi.StringInput
	// ResourceGroupName is the resource group to deploy into.
	ResourceGroupName pulumi.StringInput
	// Location is the Azure region.
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// SubnetID is the subnet for the system node pool. Azure CNI assigns a
	// subnet IP to every pod, so size it accordingly.
	SubnetID pulumi.StringInput
	// WorkspaceID is the Log Analytics workspace resource ID for monitoring.
	// When nil the monitoring addon is not enabled.
	WorkspaceID pulumi.StringInput
	// KubernetesVersion pins the AKS control plane version. Default: "1.30".
	KubernetesVersion pulumi.StringInput
	// SystemNodeCount is the system pool node count. Default: 2.
	SystemNodeCount pulumi.IntInput
	// SystemVMSize is the system pool VM size. Default: Standard_D4s_v5.
	// B-series VMs are NOT supported for system pools.
	SystemVMSize pulumi.StringInput
	// EnablePrivateCluster makes the API server private. Default: false.
	EnablePrivateCluster pulumi.BoolInput
}

// Cluster is the component resource output.
type Cluster struct {
	pulumi.ResourceState

	ClusterName pulumi.StringOutput `pulumi:"clusterName"`
	ClusterID   pulumi.StringOutput `pulumi:"clusterId"`
	// KubeconfigRaw is the base64-encoded admin kubeconfig. Treat as a secret.
	KubeconfigRaw       pulumi.StringOutput `pulumi:"kubeconfigRaw"`
	NodeResourceGroup   pulumi.StringOutput `pulumi:"nodeResourceGroup"`
	IdentityPrincipalID pulumi.StringOutput `pulumi:"identityPrincipalId"`
}

// NewCluster creates a new AKS cluster component resource.
func NewCluster(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Cluster, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Cluster{}
	err := ctx.RegisterComponentResource("udap:azure:AksCluster", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("azure/aks"),
	}

	// Resolve optional inputs to their documented defaults. Never
	// type-assert a pulumi Input to a concrete type — callers legitimately
	// pass Outputs from other resources, which would panic.
	k8sVersion := args.KubernetesVersion
	if k8sVersion == nil {
		k8sVersion = pulumi.String("1.30")
	}

	vmSize := args.SystemVMSize
	if vmSize == nil {
		vmSize = pulumi.String("Standard_D4s_v5")
	}

	nodeCount := args.SystemNodeCount
	if nodeCount == nil {
		nodeCount = pulumi.Int(2)
	}

	enablePrivateCluster := args.EnablePrivateCluster
	if enablePrivateCluster == nil {
		enablePrivateCluster = pulumi.Bool(false)
	}

	// Monitoring addon is only wired up when a workspace was supplied.
	addonProfiles := containerservice.ManagedClusterAddonProfileMap{}
	if args.WorkspaceID != nil {
		addonProfiles["omsagent"] = &containerservice.ManagedClusterAddonProfileArgs{
			Enabled: pulumi.Bool(true),
			Config: pulumi.StringMap{
				"logAnalyticsWorkspaceResourceID": args.WorkspaceID,
			},
		}
	}

	cluster, err := containerservice.NewManagedCluster(ctx, fmt.Sprintf("%s-aks", name), &containerservice.ManagedClusterArgs{
		ResourceName:      args.ClusterName,
		ResourceGroupName: args.ResourceGroupName,
		Location:          args.Location,
		KubernetesVersion: k8sVersion,
		DnsPrefix:         pulumi.Sprintf("%s-dns", args.ClusterName),

		// System-assigned managed identity
		Identity: &containerservice.ManagedClusterIdentityArgs{
			Type: containerservice.ResourceIdentityTypeSystemAssigned,
		},

		// System node pool. B-series VMs are NOT supported for system pools.
		AgentPoolProfiles: containerservice.ManagedClusterAgentPoolProfileArray{
			&containerservice.ManagedClusterAgentPoolProfileArgs{
				Name:              pulumi.String("system"),
				Mode:              pulumi.String("System"),
				Count:             nodeCount,
				MinCount:          pulumi.Int(1),
				MaxCount:          pulumi.Int(4),
				EnableAutoScaling: pulumi.Bool(true),
				VmSize:            vmSize,
				OsDiskSizeGB:      pulumi.Int(50),
				OsDiskType:        pulumi.String("Managed"),
				VnetSubnetID:      args.SubnetID,
				MaxPods:           pulumi.Int(30),
				NodeLabels: pulumi.StringMap{
					"nodepool-type": pulumi.String("system"),
					"environment":   args.Environment,
				},
				Tags: tags,
			},
		},

		// RBAC
		EnableRBAC: pulumi.Bool(true),
		AadProfile: &containerservice.ManagedClusterAADProfileArgs{
			Managed:         pulumi.Bool(true),
			EnableAzureRBAC: pulumi.Bool(true),
		},

		ApiServerAccessProfile: &containerservice.ManagedClusterAPIServerAccessProfileArgs{
			EnablePrivateCluster: enablePrivateCluster,
		},

		// Network
		NetworkProfile: &containerservice.ContainerServiceNetworkProfileArgs{
			NetworkPlugin:   pulumi.String("azure"),
			NetworkPolicy:   pulumi.String("calico"),
			LoadBalancerSku: pulumi.String("standard"),
			OutboundType:    pulumi.String("loadBalancer"),
		},

		// Monitoring
		AddonProfiles: addonProfiles,

		Tags: tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Get kubeconfig via admin credentials output
	creds := containerservice.ListManagedClusterAdminCredentialsOutput(ctx,
		containerservice.ListManagedClusterAdminCredentialsOutputArgs{
			ResourceGroupName: args.ResourceGroupName,
			ResourceName:      cluster.Name,
		})

	component.ClusterName = cluster.Name
	component.ClusterID = cluster.ID().ToStringOutput()
	component.KubeconfigRaw = creds.Kubeconfigs().Index(pulumi.Int(0)).Value().Elem()
	component.NodeResourceGroup = cluster.NodeResourceGroup.Elem()
	component.IdentityPrincipalID = cluster.IdentityProfile.MapIndex(pulumi.String("kubeletidentity")).ClientId().Elem()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"clusterName":         component.ClusterName,
		"clusterId":           component.ClusterID,
		"kubeconfigRaw":       component.KubeconfigRaw,
		"nodeResourceGroup":   component.NodeResourceGroup,
		"identityPrincipalId": component.IdentityPrincipalID,
	})

	return component, nil
}
