variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the virtual network"
  type        = string
  default     = null
}

variable "address_space" {
  description = "Address space for the virtual network (CIDR blocks)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "List of subnet objects to create"
  type = list(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = [
    { name = "public", address_prefixes = ["10.0.1.0/24"], service_endpoints = [] },
    { name = "private", address_prefixes = ["10.0.2.0/24"], service_endpoints = [] }
  ]
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
