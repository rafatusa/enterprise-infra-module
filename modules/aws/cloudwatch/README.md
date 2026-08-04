# Module: aws/cloudwatch

Creates a CloudWatch log group, optional metric alarms (CPU, memory, disk), and an optional CloudWatch dashboard for a named workload. Configurable retention and optional KMS encryption.

## Usage

```hcl
module "monitoring" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/cloudwatch?ref=v1.1.0"

  name        = "my-app"
  project     = "my-project"
  environment = "production"

  retention_in_days = 90
  kms_key_arn       = module.kms.key_arn

  # CPU alarm — fires when avg CPU > 80% for 2 consecutive 5-min periods
  enable_cpu_alarm       = true
  cpu_alarm_threshold    = 80
  alarm_actions          = [aws_sns_topic.alerts.arn]

  create_dashboard = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Log group and alarm name prefix | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| retention_in_days | Log retention (1–3653 days) | `number` | `90` | no |
| kms_key_arn | KMS key ARN for log encryption | `string` | `null` | no |
| enable_cpu_alarm | Create CPU utilization alarm | `bool` | `false` | no |
| cpu_alarm_threshold | CPU % threshold | `number` | `80` | no |
| alarm_actions | SNS ARNs for alarm actions | `list(string)` | `[]` | no |
| create_dashboard | Create CloudWatch dashboard | `bool` | `false` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `log_group_name` | CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
| `cpu_alarm_arn` | CPU alarm ARN (if created) |
| `dashboard_name` | Dashboard name (if created) |
