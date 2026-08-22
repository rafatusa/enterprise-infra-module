variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket name. Defaults to '<project>-<env>-data' when null."
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS encryption (null = SSE-S3)"
  type        = string
  default     = null
}

variable "expiration_days" {
  description = "Days after which objects expire (0 = no lifecycle rule)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
