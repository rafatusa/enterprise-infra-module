# Module: aws/s3

Creates an S3 bucket with public access fully blocked, server-side encryption always
enabled, versioning on by default, and an optional object-expiry lifecycle rule.

## Usage

```hcl
module "data" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/s3?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  # Optional: SSE-KMS instead of SSE-S3. This is an ARN, not a key ID.
  kms_key_arn = module.kms.key_arn

  versioning_enabled = true
  expiration_days    = 90
}
```

## Encryption

Encryption is always on; the only choice is which key:

| `kms_key_arn` | Algorithm |
|---|---|
| `null` (default) | `AES256` — SSE-S3, AWS-managed |
| a KMS key **ARN** | `aws:kms` — SSE-KMS with your key |

`bucket_key_enabled` is always `true`, which reduces KMS request costs.

Note the variable takes an **ARN** (`arn:aws:kms:...`), not a key ID. Pass
`module.kms.key_arn`, not `module.kms.key_id`.

## Lifecycle

`expiration_days` defaults to `0`, which creates **no lifecycle rule at all**. Set it to
a positive number to expire both current objects and noncurrent versions after that many
days.

## Bucket naming

`bucket_name` defaults to `<project_name>-<environment>-data`. S3 bucket names are
globally unique across all AWS accounts, so pass an explicit `bucket_name` if the
default collides.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `bucket_name` | S3 bucket name. Defaults to `<project>-<env>-data` when `null`. | `string` | `null` | no |
| `versioning_enabled` | Enable S3 object versioning | `bool` | `true` | no |
| `kms_key_arn` | KMS key **ARN** for SSE-KMS encryption (`null` = SSE-S3) | `string` | `null` | no |
| `expiration_days` | Days after which objects expire (`0` = no lifecycle rule) | `number` | `0` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `bucket_id` | Name/ID of the S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |
| `bucket_domain_name` | Bucket domain name |

## Notes

- All four public access block settings are hardcoded to `true`. This module cannot
  create a public bucket.
- Setting `versioning_enabled = false` sets the bucket to `Suspended`, not `Disabled` —
  S3 does not allow returning to the unversioned state once versioning has been enabled.
- There is no `force_destroy` option. A bucket containing objects will refuse to be
  destroyed; empty it first.
