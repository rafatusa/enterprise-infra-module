variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for every resource in the package (e.g. eastus)"
  type        = string
}

variable "resource_group_suffix" {
  description = "Short name appended to the resource group (e.g. app, shared, platform)"
  type        = string
  default     = "aks"
}

# --- Networking ------------------------------------------------------------

variable "address_space" {
  description = "Address space for the virtual network (CIDR blocks)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnets to create in the virtual network. Must contain one named by node_subnet_name."
  type = list(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
  }))
  default = [
    { name = "nodes", address_prefixes = ["10.0.1.0/24"], service_endpoints = [] }
  ]
}

variable "node_subnet_name" {
  description = "Name of the subnet in `subnets` that hosts the AKS node pools"
  type        = string
  default     = "nodes"

  validation {
    condition     = length(var.node_subnet_name) > 0
    error_message = "node_subnet_name must not be empty."
  }
}

variable "security_rules" {
  description = "NSG security rules applied to the node subnet. Defaults to the nsg module's allow-HTTPS plus deny-all baseline."
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
    description                = optional(string)
  }))
  default = [
    {
      name                       = "allow-https-inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Allow HTTPS inbound from internet"
    },
    {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic"
    }
  ]
}

# --- Observability ---------------------------------------------------------

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_in_days" {
  description = "Log Analytics data retention in days (30-730)"
  type        = number
  default     = 30
}

# --- Cluster ---------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.29"
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 2
}

variable "system_node_vm_size" {
  description = "VM size for system node pool nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Enable the cluster autoscaler on the system node pool"
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Minimum node count when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum node count when autoscaling is enabled"
  type        = number
  default     = 5
}

variable "user_node_pools" {
  description = "Additional user node pools, keyed by pool name"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = optional(bool)
    min_count           = optional(number)
    max_count           = optional(number)
  }))
  default = {}
}

# --- Tagging ---------------------------------------------------------------

variable "tags" {
  description = "Additional tags merged onto every resource in the package"
  type        = map(string)
  default     = {}
}
