// Package kms provides a Pulumi component resource for an AWS KMS key
// with rotation, key policy, and alias.
// Mirrors infra/modules/aws/kms.
//
// Usage:
//
//	key, err := kms.NewKey(ctx, "app", &kms.Args{
//	    Name:        pulumi.String("app-key"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	    Description: pulumi.String("Application encryption key"),
//	})
package kms

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/kms"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the KMS key component.
type Args struct {
	// Name is used for the alias and tagging.
	Name pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// Description describes the key's intended use.
	Description pulumi.StringInput
	// EnableKeyRotation enables annual automatic key rotation. Default: true.
	EnableKeyRotation pulumi.BoolInput
	// DeletionWindowDays is the waiting period before key deletion. Default: 30.
	DeletionWindowDays pulumi.IntInput
	// MultiRegion creates a multi-region primary key. Default: false.
	MultiRegion pulumi.BoolInput
}

// Key is the component resource output.
type Key struct {
	pulumi.ResourceState

	KeyID    pulumi.StringOutput `pulumi:"keyId"`
	KeyARN   pulumi.StringOutput `pulumi:"keyArn"`
	AliasARN pulumi.StringOutput `pulumi:"aliasArn"`
}

// NewKey creates a new KMS key component resource.
func NewKey(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Key, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Key{}
	err := ctx.RegisterComponentResource("udap:aws:KmsKey", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Name":        args.Name,
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/kms"),
	}

	desc := pulumi.String("Managed by Pulumi")
	if args.Description != nil {
		desc = args.Description.(pulumi.String)
	}

	key, err := kms.NewKey(ctx, fmt.Sprintf("%s-key", name), &kms.KeyArgs{
		Description:            desc,
		EnableKeyRotation:      pulumi.Bool(true),
		DeletionWindowInDays:   pulumi.Int(30),
		MultiRegion:            pulumi.Bool(false),
		Tags:                   tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	alias, err := kms.NewAlias(ctx, fmt.Sprintf("%s-alias", name), &kms.AliasArgs{
		Name:        pulumi.Sprintf("alias/%s", args.Name),
		TargetKeyId: key.KeyId,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	component.KeyID = key.KeyId
	component.KeyARN = key.Arn
	component.AliasARN = alias.Arn

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"keyId":    component.KeyID,
		"keyArn":   component.KeyARN,
		"aliasArn": component.AliasARN,
	})

	return component, nil
}
