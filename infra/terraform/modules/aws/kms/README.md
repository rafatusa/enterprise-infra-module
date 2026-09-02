# Module: aws/kms

Creates a customer-managed KMS key with annual rotation enabled and a friendly alias.

## Usage

```hcl
module "kms" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/kms?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  key_name     = "data"
  description  = "Encrypts application data at rest"
}
```

Consume it from another module:

```hcl
module "bucket" {
  source      = ".../modules/aws/s3?ref=v2.0.0"
  kms_key_arn = module.kms.key_arn   # ARN, not key_id
}
```

## Resource naming

- Key tag `Name`: `<project_name>-<environment>-<key_name>`
- Alias: `alias/<project_name>-<environment>-<key_name>`

`key_name` is a short label (e.g. `rds`, `s3`, `app`), not the full alias.

## Key policy

`key_policy` is `null` by default, which leaves the AWS default key policy in place —
full access for the account root, and IAM policies govern everything else. Supply a JSON
document to restrict or extend it:

```hcl
key_policy = data.aws_iam_policy_document.kms.json
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in naming and tags | `string` | `"project"` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `key_name` | Short name for the KMS key and alias (e.g. `rds`, `s3`, `app`) | `string` | `"app"` | no |
| `description` | KMS key description | `string` | `"Managed by Terraform"` | no |
| `deletion_window_in_days` | Days to wait before key deletion after scheduled deletion (7–30) | `number` | `30` | no |
| `enable_key_rotation` | Automatically rotate the key annually | `bool` | `true` | no |
| `key_policy` | JSON key policy document (`null` uses the AWS default) | `string` | `null` | no |
| `tags` | Additional tags merged into the key | `map(string)` | `{}` | no |

There is no `key_usage` input — the key is always a symmetric encryption key.

## Outputs

| Name | Description |
|---|---|
| `key_id` | KMS key ID |
| `key_arn` | KMS key ARN — this is what other modules want |
| `alias_name` | KMS alias name (`alias/...`) |
| `alias_arn` | KMS alias ARN |

## Notes

- `project_name` defaults to `"project"` rather than being required. This is deliberate:
  the variable is interpolated into the alias string, and a `null` default would fail
  static analysis. Always pass a real value.
- Destroying the key schedules deletion after `deletion_window_in_days`; it is not
  immediate and cannot be shortened below 7 days.
