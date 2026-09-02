# Module: aws/iam-role

Creates an IAM role for a single AWS service principal, with managed policy
attachments, an optional inline policy, and an instance profile that is **always**
created.

## Related module

`aws/iam` is a near-duplicate of this module. The difference is:

| | `aws/iam-role` (this module) | `aws/iam` |
|---|---|---|
| Instance profile | always created | optional, via `create_instance_profile` (default `false`) |
| Assume-role control | `assume_role_service` — a service principal string | `assume_role_policy` — full policy JSON |
| Role name variable | `role_name_suffix` | `role_name` |
| Role name format | `<project>-<env>-<suffix>-role` | `<project>-<env>-<name>` |

Use this module for the common EC2/ECS/Lambda case where you want a service role and an
instance profile with no ceremony. Use `aws/iam` when you need a custom trust policy
(multiple principals, conditions, cross-account) or want to skip the instance profile.
Consolidating the two is tracked as technical debt.

## Usage

```hcl
module "ec2_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam-role?ref=v2.0.0"

  project_name     = "my-app"
  environment      = "prod"
  role_name_suffix = "ec2"

  assume_role_service = "ec2.amazonaws.com"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}
```

With an inline policy:

```hcl
module "ecs_task_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam-role?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  role_name_suffix    = "ecs-task"
  assume_role_service = "ecs-tasks.amazonaws.com"

  inline_policy = data.aws_iam_policy_document.task.json
}
```

## Resource naming

- Role: `<project_name>-<environment>-<role_name_suffix>-role`
- Instance profile: `<project_name>-<environment>-<role_name_suffix>-profile`
- Inline policy: `<project_name>-<environment>-<role_name_suffix>-inline`

`role_name_suffix` is a short suffix, not the full role name.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `role_name_suffix` | Short suffix appended to the role name (e.g. `ec2`, `lambda`, `ecs`) | `string` | `"role"` | no |
| `assume_role_service` | AWS service principal that may assume this role | `string` | `"ec2.amazonaws.com"` | no |
| `managed_policy_arns` | Managed IAM policy ARNs to attach | `list(string)` | `[]` | no |
| `inline_policy` | Inline policy JSON (`null` = none) | `string` | `null` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN of the IAM role |
| `role_name` | Name of the IAM role |
| `instance_profile_arn` | ARN of the instance profile |
| `instance_profile_name` | Name of the instance profile |

The instance profile outputs are never `null` — the profile is created unconditionally.
