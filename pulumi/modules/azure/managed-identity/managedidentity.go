// Package managedidentity provides a Pulumi component resource for an Azure
// User-Assigned Managed Identity with optional role assignments.
// Mirrors infra/modules/azure/managed-identity.
//
// Usage:
//
//	mi, err := managedidentity.NewManagedIdentity(ctx, "app", &managedidentity.Args{
//	    Name:              pulumi.String("app-identity"),
//	    ResourceGroupName: rg.ResourceGroupName,
//	    Location:          rg.Location,
//	    Project:           pulumi.String("my-project"),
//	    Environment:       pulumi.String("production"),
//	})
package managedidentity

import (
	"fmt"

	"github.com/pulumi/pulumi-azure-native-sdk/authorization/v2"
	"github.com/pulumi/pulumi-azure-native-sdk/resources/v2"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// RoleAssignment defines a role to assign to the managed identity.
type RoleAssignment struct {
	// RoleDefinitionID is the Azure built-in or custom role definition ID.
	RoleDefinitionID string
	// Scope is the resource scope for the assignment (subscription, RG, resource).
	Scope string
}

// Args holds the configuration for the Managed Identity component.
type Args struct {
	// Name is the managed identity resource name.
	Name pulumi.StringInput
	// ResourceGroupName is the resource group to deploy into.
	ResourceGroupName pulumi.StringInput
	// Location is the Azure region.
	Location pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// RoleAssignments are optional role assignments for the identity.
	RoleAssignments []RoleAssignment
}

// ManagedIdentity is the component resource output.
type ManagedIdentity struct {
	pulumi.ResourceState

	IdentityName    pulumi.StringOutput `pulumi:"identityName"`
	IdentityID      pulumi.StringOutput `pulumi:"identityId"`
	PrincipalID     pulumi.StringOutput `pulumi:"principalId"`
	ClientID        pulumi.StringOutput `pulumi:"clientId"`
	TenantID        pulumi.StringOutput `pulumi:"tenantId"`
}

// NewManagedIdentity creates a new Azure Managed Identity component resource.
func NewManagedIdentity(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*ManagedIdentity, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &ManagedIdentity{}
	err := ctx.RegisterComponentResource("udap:azure:ManagedIdentity", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("azure/managed-identity"),
	}

	identity, err := resources.NewUserAssignedIdentity(ctx, fmt.Sprintf("%s-identity", name), &resources.UserAssignedIdentityArgs{
		ResourceName:      args.Name,
		ResourceGroupName: args.ResourceGroupName,
		Location:          args.Location,
		Tags:              tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Role Assignments
	for i, ra := range args.RoleAssignments {
		_, err = authorization.NewRoleAssignment(ctx,
			fmt.Sprintf("%s-role-%d", name, i),
			&authorization.RoleAssignmentArgs{
				PrincipalId:      identity.PrincipalId,
				PrincipalType:    pulumi.String("ServicePrincipal"),
				RoleDefinitionId: pulumi.String(ra.RoleDefinitionID),
				Scope:            pulumi.String(ra.Scope),
			}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	component.IdentityName = identity.Name
	component.IdentityID = identity.ID().ToStringOutput()
	component.PrincipalID = identity.PrincipalId
	component.ClientID = identity.ClientId
	component.TenantID = identity.TenantId

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"identityName": component.IdentityName,
		"identityId":   component.IdentityID,
		"principalId":  component.PrincipalID,
		"clientId":     component.ClientID,
		"tenantId":     component.TenantID,
	})

	return component, nil
}
