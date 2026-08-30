variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "role_name_suffix" {
  description = "Short suffix appended to the role name (e.g. ec2, lambda, ecs)"
  type        = string
  default     = "role"
}

variable "assume_role_service" {
  description = "AWS service principal that may assume this role (e.g. ec2.amazonaws.com)"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "managed_policy_arns" {
  description = "List of IAM managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Inline policy JSON to attach (null = none)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
