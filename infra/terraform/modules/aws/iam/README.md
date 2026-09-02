# Module: aws/iam

Creates an IAM **role** with managed policy attachments, an optional inline policy, and
an optional EC2 instance profile. The assume-role policy defaults to the EC2 service
principal so the role is usable by instances without extra configuration.

> **This module does not create IAM users.** Earlier documentation described a user /
> group module; no such resources exist here and never did. If you need a user, this is
> not the module.

## Related module

`aws/iam-role` is a near-duplicate of this module. The difference is:

| | `aws/iam` (this module) | `aws/iam-role` |
|---|---|---|
| Instance profile | optional, via `create_instance_profile` (default `false`) | always created |
| Assume-role control | `assume_role_policy` — full policy JSON | `assume_role_service` — a service principal string |
| Role name variable | `role_name` | `role_name_suffix` |
| Role name format | `<project>-<env>-<name>` | `<project>-<env>-<suffix>-role` |

Use this module when you need a custom trust policy (multiple principals, conditions,
cross-account) or want to skip the instance profile. Use `aws/iam-role` for the common
single-service case where an instance profile is always wanted. Consolidating the two is
tracked as technical debt.

## Usage

```hcl
module "app_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  role_name    = "app"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  # Attach the role to EC2 instances.
  create_instance_profile = true
}
```

Assuming a non-EC2 principal:

```hcl
module "lambda_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  role_name    = "lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  inline_policy = data.aws_iam_policy_document.lambda.json
}
```

## Resource naming

The role is named `<project_name>-<environment>-<role_name>` and the instance profile
`<project_name>-<environment>-<role_name>-profile`. `role_name` is a short suffix, not
the full role name.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `role_name` | Short suffix for the role name | `string` | `"role"` | no |
| `assume_role_policy` | IAM assume role policy JSON. Defaults to the EC2 service principal when `null`. | `string` | `null` | no |
| `managed_policy_arns` | Managed IAM policy ARNs to attach | `list(string)` | `[]` | no |
| `inline_policy` | Inline policy JSON (`null` = none) | `string` | `null` | no |
| `create_instance_profile` | Create an IAM instance profile for this role | `bool` | `false` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN of the IAM role |
| `role_name` | Name of the IAM role |
| `instance_profile_arn` | ARN of the instance profile (`null` if not created) |
| `instance_profile_name` | Name of the instance profile (`null` if not created) |
