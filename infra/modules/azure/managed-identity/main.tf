terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.project_name}-${var.environment}-${var.identity_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.identity_name}-identity"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
