variable "name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
  default     = null

  validation {
    condition     = var.name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.name))
    error_message = "Workspace name must be 3-63 chars, alphanumeric and hyphens only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the workspace."
  type        = string
  default     = null
}

variable "sku" {
  description = "SKU for the Log Analytics Workspace. PerGB2018 is the modern default."
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.sku)
    error_message = "Invalid SKU. Use PerGB2018 for most workloads."
  }
}

variable "retention_in_days" {
  description = "Number of days to retain logs (30-730)."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  description = "Daily data ingestion cap in GB. -1 disables the cap."
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Allow data ingestion from the public internet."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow querying via the public internet."
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable local (non-AAD) authentication to the workspace."
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Deploy the ContainerInsights solution (required for AKS monitoring)."
  type        = bool
  default     = false
}

variable "enable_vm_insights" {
  description = "Deploy the VMInsights solution."
  type        = bool
  default     = false
}

variable "project" {
  description = "Project identifier tag."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label tag."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
