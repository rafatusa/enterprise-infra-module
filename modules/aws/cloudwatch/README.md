# aws/cloudwatch

Provisions a CloudWatch Log Group, CPU and memory metric alarms, and a basic operational dashboard.

## Usage

```hcl
module "monitoring" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/cloudwatch?ref=v1.1.0"

  name        = "my-project"
  project     = "my-project"
  environment = "production"

  instance_id           = module.ec2.instance_id
  alarm_sns_topic_arn   = aws_sns_topic.alerts.arn
  cpu_alarm_threshold   = 80
  log_retention_days    = 30
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource name prefix | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `instance_id` | EC2 instance ID to monitor | `string` | — | yes |
| `alarm_sns_topic_arn` | SNS topic ARN for alarm notifications | `string` | `""` | no |
| `cpu_alarm_threshold` | CPU % threshold to trigger alarm | `number` | `80` | no |
| `log_retention_days` | CloudWatch log retention in days | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| `log_group_name` | CloudWatch Log Group name |
| `log_group_arn` | CloudWatch Log Group ARN |
| `cpu_alarm_arn` | CPU alarm ARN |
| `dashboard_name` | CloudWatch dashboard name |
