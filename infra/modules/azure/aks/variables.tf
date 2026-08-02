variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = null

  validation {
    condition     = var.cluster_name == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must be 3-63 chars, alphanumeric and hyphens only."
  }
}

variable "resource_group_name" {
  description = "Resource group to deploy the cluster into."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = null
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster FQDN. Defaults to cluster_name."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy. Leave null to use the latest supported."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS SLA tier: Free (no SLA), Paid or Standard (99.95% SLA)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Paid", "Standard"], var.sku_tier)
    error_message = "sku_tier must be Free, Paid, or Standard."
  }
}

variable "user_assigned_identity_id" {
  description = "Resource ID of a User Assigned Managed Identity. Leave null for system-assigned."
  type        = string
  default     = null
}

variable "azure_rbac_enabled" {
  description = "Use Azure RBAC for Kubernetes authorization."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "AAD group object IDs that receive cluster-admin access."
  type        = list(string)
  default     = []
}

variable "subnet_id" {
  description = "Subnet resource ID for the node pools."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Make the API server endpoint private."
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "Private DNS zone resource ID. 'System' lets AKS manage it."
  type        = string
  default     = "System"
}

variable "network_plugin" {
  description = "Network plugin: azure (CNI) or kubenet."
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "network_plugin must be azure, kubenet, or none."
  }
}

variable "network_policy" {
  description = "Network policy engine: azure or calico."
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "cilium"], var.network_policy)
    error_message = "network_policy must be azure, calico, or cilium."
  }
}

variable "service_cidr" {
  description = "CIDR block for Kubernetes services. Must not overlap with the VNet."
  type        = string
  default     = "10.100.0.0/16"
}

variable "dns_service_ip" {
  description = "IP within service_cidr assigned to the DNS service."
  type        = string
  default     = "10.100.0.10"
}

variable "outbound_type" {
  description = "How outbound traffic leaves the cluster."
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.outbound_type)
    error_message = "Invalid outbound_type."
  }
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
  description = "Minimum nodes in the system pool (autoscaling)."
  type        = number
  default     = 1
}

variable "system_max_count" {
  description = "Maximum nodes in the system pool (autoscaling)."
  type        = number
  default     = 5
}

variable "system_enable_autoscaling" {
  description = "Enable cluster autoscaler for the system pool."
  type        = bool
  default     = true
}

variable "system_os_disk_size_gb" {
  description = "OS disk size in GB for system nodes."
  type        = number
  default     = 100
}

variable "system_os_disk_type" {
  description = "OS disk type: Managed or Ephemeral."
  type        = string
  default     = "Managed"

  validation {
    condition     = contains(["Managed", "Ephemeral"], var.system_os_disk_type)
    error_message = "os_disk_type must be Managed or Ephemeral."
  }
}

variable "system_max_pods" {
  description = "Maximum pods per node in the system pool."
  type        = number
  default     = 110
}

variable "user_node_pools" {
  description = "List of additional (user) node pool configurations."
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID for OMS agent and diagnostics."
  type        = string
  default     = null
}

variable "enable_secret_store_csi" {
  description = "Enable the Secrets Store CSI driver (Azure Key Vault integration)."
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers."
  type        = bool
  default     = false
}

variable "oidc_issuer_enabled" {
  description = "Enable the OIDC issuer (required for Workload Identity)."
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity (requires oidc_issuer_enabled = true)."
  type        = bool
  default     = true
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
