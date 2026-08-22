terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/${var.project_name}/${var.environment}/${var.log_group_name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.log_group_name}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = { for alarm in var.metric_alarms : alarm.alarm_name => alarm }

  alarm_name          = "${var.project_name}-${var.environment}-${each.value.alarm_name}"
  alarm_description   = each.value.alarm_description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
