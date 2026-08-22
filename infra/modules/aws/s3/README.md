# Module: aws/s3

Creates an S3 bucket with versioning, server-side encryption (SSE-S3 or KMS), and public-access block enabled.

## Usage

```hcl
module "s3" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/s3?ref=v1.0.0"

  project_name        = "my-app"
  environment         = "prod"
  bucket_name         = "my-app-prod-assets"
  versioning_enabled  = true
  kms_key_id          = module.kms.key_arn   # optional, defaults to SSE-S3
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `bucket_name` | Globally unique bucket name | `string` | — | yes |
| `versioning_enabled` | Enable object versioning | `bool` | `true` | no |
| `kms_key_id` | KMS key ARN for SSE-KMS (empty = SSE-S3) | `string` | `""` | no |
| `force_destroy` | Allow destroying non-empty buckets | `bool` | `false` | no |
| `lifecycle_enabled` | Enable lifecycle transitions to IA/Glacier | `bool` | `false` | no |

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | Name of the bucket |
| `bucket_arn` | ARN of the bucket |
| `bucket_domain_name` | Regional domain name of the bucket |
