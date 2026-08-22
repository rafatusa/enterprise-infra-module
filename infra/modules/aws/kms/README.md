# Module: aws/kms

Creates a KMS customer-managed key (CMK) with automatic rotation and a human-readable alias.

## Usage

```hcl
module "kms" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/kms?ref=v1.0.0"

  project_name              = "my-app"
  environment               = "prod"
  description               = "Encryption key for S3 and RDS"
  enable_key_rotation       = true
  deletion_window_in_days   = 30
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and alias | `string` | `""` | no |
| `environment` | Deployment environment | `string` | — | yes |
| `description` | Description for the KMS key | `string` | `"Managed by Terraform"` | no |
| `enable_key_rotation` | Enable automatic annual key rotation | `bool` | `true` | no |
| `deletion_window_in_days` | Days before key is deleted after destroy | `number` | `30` | no |
| `key_usage` | Intended use of the key (`ENCRYPT_DECRYPT` or `SIGN_VERIFY`) | `string` | `"ENCRYPT_DECRYPT"` | no |

## Outputs

| Name | Description |
|---|---|
| `key_id` | KMS key ID |
| `key_arn` | ARN of the KMS key |
| `alias_arn` | ARN of the key alias |
