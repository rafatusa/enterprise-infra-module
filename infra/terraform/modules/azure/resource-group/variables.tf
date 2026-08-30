variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Short name appended to the resource group (e.g. app, shared, data)"
  type        = string
  default     = "app"
}

variable "location" {
  description = "Azure region (e.g. eastus, westeurope)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags merged onto the resource group"
  type        = map(string)
  default     = {}
}
