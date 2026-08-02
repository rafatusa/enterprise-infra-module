# azure/aks

Deploys a production-grade **Azure Kubernetes Service (AKS)** cluster with:

- Private API server endpoint
- Azure CNI networking with Network Policy
- System-assigned **or** User-assigned Managed Identity
- Azure AAD integration with Azure RBAC
- Cluster autoscaler on system and user node pools
- OIDC issuer + Workload Identity
- Secrets Store CSI driver (Key Vault integration)
- OMS Agent → Log Analytics (Container Insights)
- Control-plane diagnostic logs to Log Analytics
- Maintenance window (Sunday 02:00–04:00)

## Usage

```hcl
module "aks" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/azure/aks?ref=v1.0.0"

  cluster_name        = "platform-aks"
  resource_group_name = module.rg.name
  location            = "eastus"
  subnet_id           = module.vnet.subnet_ids["aks"]

  kubernetes_version          = "1.29"
  user_assigned_identity_id   = module.identity.id
  admin_group_object_ids      = ["<aad-group-object-id>"]
  log_analytics_workspace_id  = module.logs.id

  user_node_pools = [
    {
      name            = "apps"
      vm_size         = "Standard_D8s_v5"
      node_count      = 3
      min_count       = 2
      max_count       = 10
      os_disk_size_gb = 128
      max_pods        = 110
      node_labels     = { "role" = "apps" }
      node_taints     = []
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | AKS cluster name | `string` | — | yes |
| resource_group_name | Resource group | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| subnet_id | Subnet for node pools | `string` | — | yes |
| kubernetes_version | Kubernetes version | `string` | `null` | no |
| sku_tier | SLA tier (Free/Paid/Standard) | `string` | `Paid` | no |
| user_assigned_identity_id | User-assigned identity ID | `string` | `null` | no |
| azure_rbac_enabled | Use Azure RBAC | `bool` | `true` | no |
| admin_group_object_ids | AAD admin group IDs | `list(string)` | `[]` | no |
| private_cluster_enabled | Private API server | `bool` | `true` | no |
| network_plugin | CNI plugin | `string` | `azure` | no |
| network_policy | Network policy engine | `string` | `azure` | no |
| service_cidr | Service CIDR | `string` | `10.100.0.0/16` | no |
| availability_zones | AZs for node pools | `list(string)` | `["1","2","3"]` | no |
| system_vm_size | System node VM size | `string` | `Standard_D4s_v5` | no |
| system_node_count | System node count | `number` | `3` | no |
| system_min_count | System autoscaler min | `number` | `1` | no |
| system_max_count | System autoscaler max | `number` | `5` | no |
| user_node_pools | Additional node pools | `list(object)` | `[]` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| enable_secret_store_csi | Enable Key Vault CSI driver | `bool` | `true` | no |
| enable_defender | Enable Defender for Containers | `bool` | `false` | no |
| oidc_issuer_enabled | Enable OIDC issuer | `bool` | `true` | no |
| workload_identity_enabled | Enable Workload Identity | `bool` | `true` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | Cluster resource ID |
| cluster_name | Cluster name |
| fqdn | API server FQDN |
| private_fqdn | Private API server FQDN |
| kube_config_raw | kubeconfig (sensitive) |
| kube_admin_config_raw | Admin kubeconfig (sensitive) |
| identity_principal_id | System identity principal ID |
| kubelet_identity_object_id | Kubelet identity object ID |
| oidc_issuer_url | OIDC issuer URL |
| node_resource_group | Node resource group name |
