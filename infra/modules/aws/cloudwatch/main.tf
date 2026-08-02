###############################################################################
# modules/aws/cloudwatch/main.tf
# Reusable AWS CloudWatch module — log group + metric alarms
###############################################################################

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws/cloudwatch"
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id != "" ? var.kms_key_id : null
  tags              = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.metric_alarms

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = each.value.alarm_description
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  statistic           = each.value.statistic
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions

  dynamic "dimensions" {
    for_each = each.value.dimensions
    content {
      name  = dimensions.key
      value = dimensions.value
    }
  }

  tags = local.common_tags
}
