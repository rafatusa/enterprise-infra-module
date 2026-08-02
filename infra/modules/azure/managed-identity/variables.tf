variable "name" {
  description = "Name of the User-Assigned Managed Identity."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource Group to deploy into."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = null
}

variable "role_assignments" {
  description = "List of Azure RBAC role assignments for this identity."
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "project" {
  description = "Project tag."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
