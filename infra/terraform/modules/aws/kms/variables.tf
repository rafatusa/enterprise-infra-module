variable "project_name" {
  description = "Project name"
  type        = string
  default     = "project"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "Short name for the KMS key and alias (e.g. rds, s3, app)"
  type        = string
  default     = "app"
}

variable "description" {
  description = "KMS key description"
  type        = string
  default     = "Managed by Terraform"
}

variable "deletion_window_in_days" {
  description = "Days to wait before key deletion after scheduled deletion (7-30)"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Automatically rotate the key annually"
  type        = bool
  default     = true
}

variable "key_policy" {
  description = "JSON key policy document (null uses AWS default)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
