# Module: aws/iam-role

Creates an IAM role with a trust policy, instance profile, and managed policy attachments. Designed for use with EC2 instance profiles or cross-account roles.

## Usage

```hcl
module "iam_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/iam-role?ref=v1.0.0"

  project_name         = "my-app"
  environment          = "prod"
  role_name            = "app-server"
  assume_role_service  = "ec2.amazonaws.com"
  managed_policy_arns  = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `role_name` | Name suffix for the IAM role | `string` | — | yes |
| `assume_role_service` | AWS service principal that can assume the role | `string` | `"ec2.amazonaws.com"` | no |
| `managed_policy_arns` | Managed policy ARNs to attach | `list(string)` | `[]` | no |
| `create_instance_profile` | Create an EC2 instance profile for this role | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | ARN of the IAM role |
| `role_name` | Name of the IAM role |
| `instance_profile_arn` | ARN of the instance profile |
| `instance_profile_name` | Name of the instance profile |
