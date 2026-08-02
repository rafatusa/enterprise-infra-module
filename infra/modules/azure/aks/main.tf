##############################################################################
# Module: azure/aks
# Purpose: Production-grade AKS cluster with system + user node pools,
#          Azure RBAC, Workload Identity, OMS agent, and diagnostic settings.
##############################################################################

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix != null ? var.dns_prefix : var.cluster_name
  kubernetes_version  = var.kubernetes_version

  node_resource_group = "${var.resource_group_name}-nodes"

  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = false

  sku_tier = var.sku_tier

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = var.azure_rbac_enabled
    admin_group_object_ids = var.admin_group_object_ids
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity_id == null ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity_id != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [var.user_assigned_identity_id]
    }
  }

  default_node_pool {
    name                         = "system"
    node_count                   = var.system_node_count
    min_count                    = var.system_min_count
    max_count                    = var.system_max_count
    enable_auto_scaling          = var.system_enable_autoscaling
    vm_size                      = var.system_vm_size
    os_disk_size_gb              = var.system_os_disk_size_gb
    os_disk_type                 = var.system_os_disk_type
    vnet_subnet_id               = var.subnet_id
    zones                        = var.availability_zones
    max_pods                     = var.system_max_pods
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }

    node_labels = {
      "role" = "system"
    }
  }

  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    outbound_type     = var.outbound_type
    load_balancer_sku = "standard"
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_secret_store_csi ? [1] : []
    content {
      secret_rotation_enabled  = true
      secret_rotation_interval = "2m"
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_defender && var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  http_application_routing_enabled  = false
  role_based_access_control_enabled = true

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 4]
    }
  }

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "azure/aks"
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = { for np in var.user_node_pools : np.name => np }

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.value.name
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  enable_auto_scaling   = true
  vnet_subnet_id        = each.value.subnet_id != null ? each.value.subnet_id : var.subnet_id
  os_disk_size_gb       = each.value.os_disk_size_gb
  max_pods              = each.value.max_pods
  zones                 = var.availability_zones
  mode                  = "User"

  node_labels = merge(
    { "role" = each.value.name },
    each.value.node_labels
  )

  node_taints = each.value.node_taints

  upgrade_settings {
    max_surge = "33%"
  }

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.cluster_name}-diag"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-audit" }
  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "cluster-autoscaler" }
  enabled_log { category = "guard" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
