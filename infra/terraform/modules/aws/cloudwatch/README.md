# Module: aws/cloudwatch

Creates one or more CloudWatch log groups with configurable retention and optional KMS encryption.

## Usage

```hcl
module "cloudwatch" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/cloudwatch?ref=v2.0.0"

  project_name      = "my-app"
  environment       = "prod"
  log_group_name    = "/my-app/prod/app"
  retention_in_days = 90
  kms_key_id        = module.kms.key_arn   # optional
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in tags | `string` | `""` | no |
| `environment` | Deployment environment | `string` | — | yes |
| `log_group_name` | Full name of the CloudWatch log group | `string` | — | yes |
| `retention_in_days` | Log retention period in days | `number` | `30` | no |
| `kms_key_id` | KMS key ARN for log encryption (empty = AWS-managed) | `string` | `""` | no |

## Outputs

| Name | Description |
|---|---|
| `log_group_name` | Name of the log group |
| `log_group_arn` | ARN of the log group |
