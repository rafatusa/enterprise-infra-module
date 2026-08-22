terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project_name}-${var.environment}-law"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-law"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
