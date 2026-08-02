# package: azure-aks

**Production-ready Azure AKS environment** — a single module reference that
automatically provisions the full stack:

| Layer | Resources |
|-------|-----------|
| **Foundation** | Resource Group |
| **Network** | VNet, system subnet, user subnet, NSG (with subnet associations) |
| **Observability** | Log Analytics Workspace, Container Insights solution |
| **Identity** | User Assigned Managed Identity |
| **Compute** | AKS cluster (private), system node pool, configurable user node pools |
| **Security** | Azure AAD + RBAC, Workload Identity, OIDC issuer, Secrets Store CSI |

## Usage

```hcl
module "aks_env" {
  source = "github.com/your-org/terraform-enterprise-modules//packages/azure-aks?ref=v1.0.0"

  cluster_name        = "platform-aks"
  resource_group_name = "platform-aks-rg"
  location            = "eastus"

  kubernetes_version     = "1.29"
  admin_group_object_ids = ["<aad-group-object-id>"]

  system_vm_size    = "Standard_D4s_v5"
  system_node_count = 3
  system_min_count  = 1
  system_max_count  = 5

  user_node_pools = [
    {
      name            = "apps"
      vm_size         = "Standard_D8s_v5"
      node_count      = 3
      min_count       = 2
      max_count       = 20
      os_disk_size_gb = 128
      max_pods        = 110
      node_labels     = { role = "apps" }
    }
  ]

  log_retention_days = 90

  tags = {
    Project     = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Grant AcrPull to the kubelet identity so nodes can pull from a private registry:
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = module.aks_env.kubelet_identity_object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Cluster name + resource prefix | `string` | — | yes |
| resource_group_name | Resource group to create | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| vnet_address_space | VNet address space | `list(string)` | `["10.0.0.0/8"]` | no |
| system_subnet_cidr | System node pool subnet CIDR | `string` | `10.1.0.0/16` | no |
| user_subnet_cidr | User node pool subnet CIDR | `string` | `10.2.0.0/16` | no |
| kubernetes_version | Kubernetes version | `string` | `null` | no |
| sku_tier | SLA tier | `string` | `Paid` | no |
| private_cluster_enabled | Private API server | `bool` | `true` | no |
| admin_group_object_ids | AAD admin group IDs | `list(string)` | `[]` | no |
| system_vm_size | System node VM size | `string` | `Standard_D4s_v5` | no |
| system_node_count | System node count | `number` | `3` | no |
| system_min_count | System autoscaler min | `number` | `1` | no |
| system_max_count | System autoscaler max | `number` | `5` | no |
| user_node_pools | Additional node pools | `list(object)` | `[]` | no |
| log_retention_days | Log Analytics retention | `number` | `90` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

`resource_group_name`, `resource_group_id`,
`vnet_id`, `vnet_name`, `system_subnet_id`, `user_subnet_id`,
`log_analytics_workspace_id`, `log_analytics_workspace_name`,
`aks_identity_id`, `aks_identity_principal_id`, `aks_identity_client_id`,
`cluster_id`, `cluster_name`, `cluster_fqdn`, `cluster_private_fqdn`,
`kube_config_raw`, `kube_admin_config_raw`,
`oidc_issuer_url`, `kubelet_identity_object_id`, `node_resource_group`

## Security defaults

- API server is **private** by default
- **Azure AAD + Azure RBAC** — no local accounts
- **Workload Identity** + OIDC issuer enabled (pod-level IAM without secrets)
- **Secrets Store CSI** (Key Vault integration) enabled
- System pool runs only critical addons (`only_critical_addons_enabled = true`)
- Maintenance window set to Sunday 02:00–04:00
