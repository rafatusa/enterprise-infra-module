// Package s3 provides a Pulumi component resource for an AWS S3 bucket
// with versioning, server-side encryption, lifecycle rules, and public access blocking.
// Mirrors infra/terraform/modules/aws/s3.
//
// Usage:
//
//	bucket, err := s3.NewBucket(ctx, "assets", &s3.Args{
//	    BucketName:  pulumi.String("my-project-assets"),
//	    Project:     pulumi.String("my-project"),
//	    Environment: pulumi.String("production"),
//	})
package s3

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v6/go/aws/s3"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

// Args holds the configuration for the S3 bucket component.
//
// The boolean toggles are plain *bool rather than pulumi.BoolInput because
// they decide whether a resource is created at all, which must be known at
// construction time. Leave them nil to accept the documented default.
type Args struct {
	// BucketName is the globally unique S3 bucket name.
	BucketName pulumi.StringInput
	// Project is used for tagging.
	Project pulumi.StringInput
	// Environment tag value.
	Environment pulumi.StringInput
	// EnableVersioning enables S3 versioning. Default: true.
	EnableVersioning *bool
	// EnableEncryption enables AES-256 server-side encryption. Default: true.
	EnableEncryption *bool
	// BlockPublicAccess blocks all public access. Default: true.
	BlockPublicAccess *bool
	// NoncurrentVersionExpirationDays sets lifecycle for old versions.
	// Default: 30. Requires versioning to be enabled.
	NoncurrentVersionExpirationDays pulumi.IntInput
}

// Bucket is the component resource output.
type Bucket struct {
	pulumi.ResourceState

	BucketID   pulumi.StringOutput `pulumi:"bucketId"`
	BucketARN  pulumi.StringOutput `pulumi:"bucketArn"`
	BucketName pulumi.StringOutput `pulumi:"bucketName"`
}

// boolOrDefault resolves an optional *bool to its default.
func boolOrDefault(v *bool, def bool) bool {
	if v == nil {
		return def
	}
	return *v
}

// NewBucket creates a new S3 bucket component resource.
func NewBucket(ctx *pulumi.Context, name string, args *Args, opts ...pulumi.ResourceOption) (*Bucket, error) {
	if args == nil {
		return nil, fmt.Errorf("args must not be nil")
	}

	component := &Bucket{}
	err := ctx.RegisterComponentResource("udap:aws:S3Bucket", name, component, opts...)
	if err != nil {
		return nil, err
	}

	resourceOpts := []pulumi.ResourceOption{pulumi.Parent(component)}

	tags := pulumi.StringMap{
		"Project":     args.Project,
		"Environment": args.Environment,
		"ManagedBy":   pulumi.String("pulumi"),
		"Module":      pulumi.String("aws/s3"),
	}

	enableVersioning := boolOrDefault(args.EnableVersioning, true)
	enableEncryption := boolOrDefault(args.EnableEncryption, true)
	blockPublicAccess := boolOrDefault(args.BlockPublicAccess, true)

	noncurrentDays := args.NoncurrentVersionExpirationDays
	if noncurrentDays == nil {
		noncurrentDays = pulumi.Int(30)
	}

	// Bucket
	bucket, err := s3.NewBucket(ctx, fmt.Sprintf("%s-bucket", name), &s3.BucketArgs{
		Bucket: args.BucketName,
		Tags:   tags,
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Block Public Access
	if blockPublicAccess {
		_, err = s3.NewBucketPublicAccessBlock(ctx, fmt.Sprintf("%s-public-access-block", name), &s3.BucketPublicAccessBlockArgs{
			Bucket:                bucket.ID(),
			BlockPublicAcls:       pulumi.Bool(true),
			BlockPublicPolicy:     pulumi.Bool(true),
			IgnorePublicAcls:      pulumi.Bool(true),
			RestrictPublicBuckets: pulumi.Bool(true),
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// Versioning. S3 has no way back to the unversioned state once enabled,
	// so disabling this maps to Suspended, matching the Terraform module.
	versioningStatus := "Suspended"
	if enableVersioning {
		versioningStatus = "Enabled"
	}
	_, err = s3.NewBucketVersioningV2(ctx, fmt.Sprintf("%s-versioning", name), &s3.BucketVersioningV2Args{
		Bucket: bucket.ID(),
		VersioningConfiguration: &s3.BucketVersioningV2VersioningConfigurationArgs{
			Status: pulumi.String(versioningStatus),
		},
	}, resourceOpts...)
	if err != nil {
		return nil, err
	}

	// Server-Side Encryption
	if enableEncryption {
		_, err = s3.NewBucketServerSideEncryptionConfigurationV2(ctx, fmt.Sprintf("%s-sse", name), &s3.BucketServerSideEncryptionConfigurationV2Args{
			Bucket: bucket.ID(),
			Rules: s3.BucketServerSideEncryptionConfigurationV2RuleArray{
				&s3.BucketServerSideEncryptionConfigurationV2RuleArgs{
					ApplyServerSideEncryptionByDefault: &s3.BucketServerSideEncryptionConfigurationV2RuleApplyServerSideEncryptionByDefaultArgs{
						SseAlgorithm: pulumi.String("AES256"),
					},
					BucketKeyEnabled: pulumi.Bool(true),
				},
			},
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	// Lifecycle Rule. Only meaningful when versioning produces noncurrent
	// versions to expire.
	if enableVersioning {
		_, err = s3.NewBucketLifecycleConfigurationV2(ctx, fmt.Sprintf("%s-lifecycle", name), &s3.BucketLifecycleConfigurationV2Args{
			Bucket: bucket.ID(),
			Rules: s3.BucketLifecycleConfigurationV2RuleArray{
				&s3.BucketLifecycleConfigurationV2RuleArgs{
					Id:     pulumi.String("expire-old-versions"),
					Status: pulumi.String("Enabled"),
					NoncurrentVersionExpiration: &s3.BucketLifecycleConfigurationV2RuleNoncurrentVersionExpirationArgs{
						NoncurrentDays: noncurrentDays,
					},
				},
			},
		}, resourceOpts...)
		if err != nil {
			return nil, err
		}
	}

	component.BucketID = bucket.ID().ToStringOutput()
	component.BucketARN = bucket.Arn
	component.BucketName = bucket.Bucket.Elem()

	ctx.RegisterResourceOutputs(component, pulumi.Map{
		"bucketId":   component.BucketID,
		"bucketArn":  component.BucketARN,
		"bucketName": component.BucketName,
	})

	return component, nil
}
