output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "FQDN of the AKS API server."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "Private FQDN of the AKS API server (private clusters only)."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster. Handle as a secret."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_admin_config_raw" {
  description = "Raw admin kubeconfig (cluster-admin). Handle as a secret."
  value       = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive   = true
}

output "identity_principal_id" {
  description = "Principal ID of the cluster's system-assigned identity (if used)."
  value       = try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null)
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet managed identity (for ACR role assignment)."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL (for Workload Identity federation)."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  description = "Name of the auto-created node resource group."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
