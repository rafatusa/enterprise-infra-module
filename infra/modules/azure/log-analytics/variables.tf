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

variable "resource_group_name" {
  description = "Resource group for the workspace"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = null
}

variable "sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Data retention in days (30-730)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
