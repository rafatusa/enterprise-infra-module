output "id" {
  description = "The resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "The name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "The globally unique workspace ID (used in agent configurations)."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "The primary shared key for agent-based ingestion."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "The secondary shared key for agent-based ingestion."
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}
