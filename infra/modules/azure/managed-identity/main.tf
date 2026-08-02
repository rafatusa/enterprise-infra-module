##############################################################################
# Module: azure/managed-identity
# Purpose: User-Assigned Managed Identity with optional RBAC role assignments.
##############################################################################

locals {
  merged_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "azure/managed-identity"
    },
    var.tags
  )
}

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.merged_tags
}

resource "azurerm_role_assignment" "this" {
  for_each = {
    for idx, ra in var.role_assignments : tostring(idx) => ra
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}
