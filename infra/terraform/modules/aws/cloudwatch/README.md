# Module: aws/cloudwatch

Creates a CloudWatch log group and, optionally, a set of metric alarms.

## Usage

```hcl
module "logs" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/cloudwatch?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  # SUFFIX only — see below.
  log_group_name    = "app"
  retention_in_days = 90
  kms_key_id        = module.kms.key_arn
}
```

## `log_group_name` is a suffix, not a full path

The module builds the log group name as:

```
/aws/<project_name>/<environment>/<log_group_name>
```

So the example above creates `/aws/my-app/prod/app`.

Passing a full path produces a doubled name — `log_group_name = "/my-app/prod/app"`
yields `/aws/my-app/prod//my-app/prod/app`. Pass the last segment only.

The full resolved name is available from the `log_group_name` output.

## Metric alarms

`metric_alarms` takes a list of objects; **every field is required** on each object (the
type has no optional attributes). Alarms are keyed by `alarm_name` and the final alarm is
named `<project_name>-<environment>-<alarm_name>`.

```hcl
module "logs" {
  # ...
  metric_alarms = [
    {
      alarm_name          = "cpu-high"
      alarm_description   = "CPU above 80% for 10 minutes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_actions       = [aws_sns_topic.alerts.arn]
      ok_actions          = [aws_sns_topic.alerts.arn]
    },
  ]
}
```

Pass `alarm_actions = []` and `ok_actions = []` if you do not want notifications — the
fields must still be present.

The module does not create alarm dimensions. Alarms without dimensions apply across the
whole namespace; add dimension support in your own configuration if you need to scope an
alarm to a specific resource.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in naming and tags | `string` | `"project"` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `log_group_name` | Log group name **suffix** (prefixed with `/aws/<project>/<env>/`) | `string` | `"app"` | no |
| `retention_in_days` | Log retention in days (`0` = never expire) | `number` | `30` | no |
| `kms_key_id` | KMS key **ARN** for log encryption (`null` = unencrypted) | `string` | `null` | no |
| `metric_alarms` | CloudWatch metric alarms to create (see above) | `list(object(...))` | `[]` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

`project_name` defaults to `"project"` rather than being required because it is
interpolated into the log group name, and a `null` default would fail static analysis.
Always pass a real value.

Despite its name, `kms_key_id` takes an ARN — pass `module.kms.key_arn`.

## Outputs

| Name | Description |
|---|---|
| `log_group_name` | Full resolved CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
| `alarm_arns` | Map of alarm name to ARN (empty when no alarms are defined) |

## Notes

- `retention_in_days` must be one of the values CloudWatch accepts (1, 3, 5, 7, 14, 30,
  60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653) or
  `0` for never. Other values are rejected at apply time.
- Encrypting a log group requires the KMS key policy to permit the CloudWatch Logs
  service principal for your region.
