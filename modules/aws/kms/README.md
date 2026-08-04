# aws/kms

Provisions a KMS Customer Managed Key (CMK) with an alias and automatic annual rotation.

## Usage

```hcl
module "kms" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/kms?ref=v1.1.0"

  name        = "my-project"
  project     = "my-project"
  environment = "production"
  description = "Encryption key for my-project application data"

  key_administrators = ["arn:aws:iam::123456789012:role/my-admin-role"]
  key_users          = ["arn:aws:iam::123456789012:role/my-app-role"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Key alias suffix | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `description` | Key description | `string` | `"Managed by Terraform"` | no |
| `key_administrators` | IAM ARNs with key admin permissions | `list(string)` | `[]` | no |
| `key_users` | IAM ARNs with key usage permissions | `list(string)` | `[]` | no |
| `enable_rotation` | Enable automatic key rotation | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `key_id` | KMS key ID |
| `key_arn` | KMS key ARN |
| `alias_arn` | KMS alias ARN |
