variable "name" {
  description = "Name of the Network Security Group."
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

variable "security_rules" {
  description = "List of security rule definitions."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = optional(string, "")
  }))
  default = []
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate this NSG with."
  type        = list(string)
  default     = []
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
