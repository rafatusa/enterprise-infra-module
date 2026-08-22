variable "project_name" {
  description = "Project name"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "log_group_name" {
  description = "Log group name suffix (prefixed with /aws/<project>/<env>/)"
  type        = string
  default     = "app"
}

variable "retention_in_days" {
  description = "Log retention in days (0 = never expire)"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ARN for log encryption (null = unencrypted)"
  type        = string
  default     = null
}

variable "metric_alarms" {
  description = "CloudWatch metric alarms to create"
  type = list(object({
    alarm_name          = string
    alarm_description   = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_actions       = list(string)
    ok_actions          = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
