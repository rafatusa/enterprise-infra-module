variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
  default     = null
}

variable "enable_versioning" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS encryption (uses SSE-S3 when empty)."
  type        = string
  default     = ""
}

variable "lifecycle_rules" {
  description = "List of lifecycle rule objects."
  type = list(object({
    id                                 = string
    enabled                            = bool
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    transition_days                    = optional(number)
    transition_storage_class           = optional(string, "STANDARD_IA")
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS configuration rules."
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    max_age_seconds = optional(number, 3600)
  }))
  default = []
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
