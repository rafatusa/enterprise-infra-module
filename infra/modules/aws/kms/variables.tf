variable "name" {
  description = "Alias name for the KMS key (will be prefixed with alias/)."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the KMS key's purpose."
  type        = string
  default     = "Managed by Terraform"
}

variable "deletion_window_in_days" {
  description = "Number of days before the key is permanently deleted after scheduling deletion (7-30)."
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation."
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Create a multi-Region primary key (replicable to other regions)."
  type        = bool
  default     = false
}

variable "key_administrators" {
  description = "List of IAM ARNs that can administer (but not use) the key."
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs that can use the key for cryptographic operations."
  type        = list(string)
  default     = []
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
