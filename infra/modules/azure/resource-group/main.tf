##############################################################################
# Module: azure/resource-group
# Purpose: Creates an Azure Resource Group with standard tags.
##############################################################################

locals {
  merged_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "azure/resource-group"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = local.merged_tags
}
