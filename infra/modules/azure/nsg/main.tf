##############################################################################
# Module: azure/nsg
# Purpose: Network Security Group with configurable rules and subnet associations.
##############################################################################

locals {
  merged_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "azure/nsg"
    },
    var.tags
  )
}

resource "azurerm_network_security_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.merged_tags

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = security_rule.value.description
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id
}
