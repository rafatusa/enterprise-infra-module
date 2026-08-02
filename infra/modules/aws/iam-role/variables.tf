variable "name" {
  description = "Name of the IAM role."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the IAM role."
  type        = string
  default     = "Managed by Terraform"
}

variable "assume_role_principals" {
  description = "List of AWS service or account principals that can assume this role (e.g. 'ec2.amazonaws.com', 'eks.amazonaws.com')."
  type        = list(string)
  default     = null
}

variable "assume_role_type" {
  description = "Type of the principal: Service | AWS | Federated."
  type        = string
  default     = "Service"
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "JSON-encoded inline policy document to attach to the role (optional)."
  type        = string
  default     = ""
}

variable "inline_policy_name" {
  description = "Name for the inline policy (required when inline_policy_json is set)."
  type        = string
  default     = "inline-policy"
}

variable "max_session_duration" {
  description = "Maximum CLI/API session duration in seconds (3600-43200)."
  type        = number
  default     = 3600
}

variable "path" {
  description = "IAM path for the role."
  type        = string
  default     = "/"
}

variable "permissions_boundary_arn" {
  description = "ARN of the IAM permissions boundary policy to attach (optional)."
  type        = string
  default     = ""
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
