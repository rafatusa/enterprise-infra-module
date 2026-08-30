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
  description = "Azure region for the AKS cluster"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for the AKS node pool"
  type        = string
  default     = null
}

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
  description = "Enable cluster autoscaler on the system node pool"
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
  description = "Map of additional user node pool configurations"
  type = map(object({
    vm_size             = string
    node_count          = number
    enable_auto_scaling = optional(bool)
    min_count           = optional(number)
    max_count           = optional(number)
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for OMS agent (null to disable)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
