# Module: aws/iam

Creates an IAM user with optional group membership and managed policy attachments.

## Usage

```hcl
module "iam" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  username     = "ci-deployer"
  policy_arns  = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `username` | IAM username | `string` | — | yes |
| `policy_arns` | Managed policy ARNs to attach to the user | `list(string)` | `[]` | no |
| `create_group` | Create a dedicated IAM group for the user | `bool` | `false` | no |
| `path` | IAM path prefix | `string` | `"/"` | no |

## Outputs

| Name | Description |
|---|---|
| `user_arn` | ARN of the IAM user |
| `user_name` | Name of the IAM user |
| `group_name` | Name of the IAM group (if created) |
