variable "name" {
  description = "Base name for CloudWatch resources (log group, alarms, dashboard)."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log group retention period in days."
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for log group encryption (optional)."
  type        = string
  default     = ""
}

variable "metric_alarms" {
  description = "Map of CloudWatch metric alarm configurations."
  type = map(object({
    alarm_description   = string
    metric_name         = string
    namespace           = string
    statistic           = string
    period              = number
    evaluation_periods  = number
    threshold           = number
    comparison_operator = string
    alarm_actions       = optional(list(string), [])
    ok_actions          = optional(list(string), [])
    dimensions          = optional(map(string), {})
  }))
  default = {}
}

variable "project" {
  description = "Project identifier applied as a tag."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
