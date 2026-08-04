# Module: aws/kms

Creates an AWS KMS Customer Managed Key (CMK) with alias, optional key rotation, multi-region support, and a least-privilege key policy.

## Usage

```hcl
module "kms" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/kms?ref=v1.1.0"

  name        = "my-app-eks"
  description = "KMS key for EKS secrets encryption"
  project     = "my-project"
  environment = "production"

  enable_key_rotation = true
  key_users           = [module.eks_cluster_role.role_arn]
  key_admins          = ["arn:aws:iam::123456789012:role/platform-admin"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Key alias name (without `alias/` prefix) | `string` | — | yes |
| description | Key description | `string` | `Managed by Terraform` | no |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| enable_key_rotation | Enable annual automatic rotation | `bool` | `true` | no |
| multi_region | Create multi-region key | `bool` | `false` | no |
| deletion_window_in_days | Key deletion window | `number` | `30` | no |
| key_users | ARNs allowed to use the key | `list(string)` | `[]` | no |
| key_admins | ARNs allowed to manage the key | `list(string)` | `[]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `key_id` | KMS key ID |
| `key_arn` | KMS key ARN |
| `alias_arn` | Key alias ARN |
| `alias_name` | Key alias name |
