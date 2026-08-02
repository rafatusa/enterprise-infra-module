variable "name" {
  description = "Name of the Azure Resource Group."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the Resource Group (e.g. eastus, westeurope)."
  type        = string
  default     = null
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
