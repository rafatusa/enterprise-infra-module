output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "cluster_identity" {
  description = "The system-assigned identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.identity[0]
}

output "node_resource_group" {
  description = "The auto-generated resource group for AKS node resources"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
