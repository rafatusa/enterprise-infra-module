output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_names" {
  description = "List of subnet names"
  value       = keys(azurerm_subnet.this)
}
