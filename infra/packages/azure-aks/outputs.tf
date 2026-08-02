###############################################################################
# Package: azure-aks — outputs
###############################################################################

output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = module.aks.cluster_id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "fqdn" {
  description = "Public FQDN of the AKS API server."
  value       = module.aks.fqdn
}

output "private_fqdn" {
  description = "Private FQDN of the AKS API server (private clusters only)."
  value       = module.aks.private_fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster. Handle as a secret."
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the Resource Group."
  value       = module.resource_group.name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = module.vnet.subnet_ids
}

output "managed_identity_client_id" {
  description = "Client ID of the AKS managed identity (for Workload Identity)."
  value       = module.managed_identity.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the AKS managed identity."
  value       = module.managed_identity.principal_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = module.log_analytics.id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for Workload Identity federation."
  value       = module.aks.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity (for ACR pull role assignment)."
  value       = module.aks.kubelet_identity_object_id
}
