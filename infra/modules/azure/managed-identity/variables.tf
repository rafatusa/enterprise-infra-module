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

variable "identity_name" {
  description = "Short name for the managed identity (e.g. app, aks)"
  type        = string
  default     = "app"
}

variable "resource_group_name" {
  description = "Resource group to create the identity in"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
