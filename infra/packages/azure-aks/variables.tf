###############################################################################
# Package: azure-aks — input variables
###############################################################################

variable "cluster_name" {
  description = "Name of the AKS cluster. Used as a prefix for all resources."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to create."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region (e.g. eastus, westeurope)."
  type        = string
  default     = null
}

variable "project" {
  description = "Project identifier applied as a tag to all resources."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network."
  type        = string
  default     = "10.0.0.0/8"
}

variable "system_subnet_cidr" {
  description = "CIDR block for the AKS system node pool subnet."
  type        = string
  default     = "10.240.0.0/16"
}

variable "user_subnet_cidr" {
  description = "CIDR block for the AKS user node pool subnet."
  type        = string
  default     = "10.241.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy on AKS. null uses the latest supported."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Deploy a private AKS cluster (API server accessible only within VNet)."
  type        = bool
  default     = false
}

variable "admin_group_object_ids" {
  description = "AAD group object IDs that receive cluster-admin access."
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for node pools."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "system_vm_size" {
  description = "VM size for the system node pool."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_count" {
  description = "Initial node count in the system pool."
  type        = number
  default     = 3
}

variable "system_min_count" {
  description = "Minimum nodes in the system pool."
  type        = number
  default     = 1
}

variable "system_max_count" {
  description = "Maximum nodes in the system pool."
  type        = number
  default     = 5
}

variable "user_node_pools" {
  description = "List of additional user node pool configurations."
  type = list(object({
    name            = string
    vm_size         = string
    node_count      = number
    min_count       = number
    max_count       = number
    os_disk_size_gb = number
    max_pods        = number
    subnet_id       = optional(string)
    node_labels     = optional(map(string), {})
    node_taints     = optional(list(string), [])
  }))
  default = []
}

variable "log_retention_days" {
  description = "Log Analytics Workspace retention in days."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
