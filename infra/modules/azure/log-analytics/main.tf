##############################################################################
# Module: azure/log-analytics
# Purpose: Log Analytics Workspace with optional Container Insights and VM Insights.
##############################################################################

locals {
  merged_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "azure/log-analytics"
    },
    var.tags
  )
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku                           = var.sku
  retention_in_days             = var.retention_in_days
  daily_quota_gb                = var.daily_quota_gb
  internet_ingestion_enabled    = var.internet_ingestion_enabled
  internet_query_enabled        = var.internet_query_enabled
  local_authentication_disabled = var.local_authentication_disabled

  tags = local.merged_tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_log_analytics_solution" "vm_insights" {
  count = var.enable_vm_insights ? 1 : 0

  solution_name         = "VMInsights"
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}
