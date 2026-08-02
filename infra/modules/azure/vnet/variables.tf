variable "name" {
  description = "Name of the Virtual Network."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the Resource Group to deploy into."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = null
}

variable "address_space" {
  description = "List of address spaces for the VNet (CIDR notation)."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS server IPs. Empty list uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet definitions. Key = subnet name."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }), null)
  }))
  default = {}
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
  description = "Additional tags to merge."
  type        = map(string)
  default     = {}
}
