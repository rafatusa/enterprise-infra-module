output "workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.this.name
}

output "primary_shared_key" {
  description = "Primary shared key for the workspace"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "workspace_customer_id" {
  description = "Log Analytics workspace customer ID (used in agents)"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}
