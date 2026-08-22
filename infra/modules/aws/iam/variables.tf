variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "role_name" {
  description = "Short suffix for the role name"
  type        = string
  default     = "role"
}

variable "assume_role_policy" {
  description = "IAM assume role policy JSON. Defaults to EC2 service principal when null."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Inline policy JSON (null = none)"
  type        = string
  default     = null
}

variable "create_instance_profile" {
  description = "Create an IAM instance profile for this role"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
