# Module: aws/s3

Creates an S3 bucket with public access blocked, versioning, SSE-KMS or SSE-S3 encryption, and configurable lifecycle rules. All public access is blocked by default.

## Usage

```hcl
module "s3" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/s3?ref=v1.1.0"

  bucket_name = "my-project-assets"
  project     = "my-project"
  environment = "production"

  versioning_enabled = true
  kms_key_arn        = module.kms.key_arn   # omit to use SSE-S3

  lifecycle_rules = [
    {
      id      = "expire-old-versions"
      enabled = true
      noncurrent_version_expiration_days = 90
    }
  ]
}
```

## Security Defaults

- All public access blocked (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`)
- Server-side encryption enabled (SSE-KMS when `kms_key_arn` provided, else SSE-S3)
- Versioning disabled by default — enable for stateful workloads

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket_name | S3 bucket name (globally unique) | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| versioning_enabled | Enable versioning | `bool` | `false` | no |
| kms_key_arn | KMS key ARN (SSE-KMS) | `string` | `null` | no |
| lifecycle_rules | Lifecycle rules | `list(object)` | `[]` | no |
| force_destroy | Allow non-empty bucket destroy | `bool` | `false` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket name |
| `bucket_arn` | Bucket ARN |
| `bucket_name` | Bucket name (alias) |
| `bucket_domain_name` | Bucket regional domain name |
