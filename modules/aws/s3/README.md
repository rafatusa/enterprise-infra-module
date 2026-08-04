# aws/s3

Provisions an S3 bucket with versioning, KMS server-side encryption, lifecycle rules, and public access block.

## Usage

```hcl
module "s3" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/s3?ref=v1.1.0"

  name        = "my-project-assets"
  project     = "my-project"
  environment = "production"
  kms_key_arn = module.kms.key_arn

  versioning_enabled      = true
  lifecycle_expiry_days   = 90
}
```

## Security defaults

| Default | Detail |
|---------|--------|
| Public access | Fully blocked (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) |
| Encryption | AWS KMS SSE (CMK via `kms_key_arn`) |
| Versioning | Enabled by default |
| TLS only | `aws:SecureTransport` deny policy applied |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Bucket name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `kms_key_arn` | KMS key ARN for SSE | `string` | — | yes |
| `versioning_enabled` | Enable versioning | `bool` | `true` | no |
| `lifecycle_expiry_days` | Days before object expiry | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name/ID |
| `bucket_arn` | Bucket ARN |
| `bucket_name` | Bucket name |
