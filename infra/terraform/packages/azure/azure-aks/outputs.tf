output "resource_group_name" {
  description = "Name of the resource group holding the platform"
  value       = module.resource_group.resource_group_name
}

output "location" {
  description = "Azure region the platform was deployed to"
  value       = module.resource_group.location
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = module.vnet.subnet_ids
}

output "nsg_id" {
  description = "ID of the network security group applied to the node subnet"
  value       = module.nsg.nsg_id
}

output "identity_id" {
  description = "Resource ID of the user-assigned managed identity"
  value       = module.identity.identity_id
}

output "identity_principal_id" {
  description = "Service principal (object) ID of the managed identity"
  value       = module.identity.principal_id
}

output "identity_client_id" {
  description = "Client ID of the managed identity"
  value       = module.identity.client_id
}

output "workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = module.log_analytics.workspace_id
}

output "workspace_name" {
  description = "Log Analytics workspace name"
  value       = module.log_analytics.workspace_name
}

output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

output "node_resource_group" {
  description = "Auto-generated resource group holding the AKS node resources"
  value       = module.aks.node_resource_group
}
