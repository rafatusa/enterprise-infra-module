# azure/aks

Provisions a production-grade AKS cluster with private API server, Azure AD RBAC, Workload Identity, Azure CNI, and CSI secret store.

## Usage

```hcl
module "aks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/aks?ref=v1.1.0"

  cluster_name        = "my-cluster"
  project             = "my-project"
  environment         = "production"
  resource_group_name = module.rg.name
  location            = module.rg.location

  kubernetes_version     = "1.30"
  node_subnet_id         = module.vnet.subnet_ids["aks-nodes"]
  pod_subnet_id          = module.vnet.subnet_ids["aks-pods"]
  log_analytics_id       = module.log_analytics.workspace_id
  admin_group_object_ids = ["<aad-admin-group-object-id>"]

  default_node_pool = {
    vm_size    = "Standard_D2s_v3"
    node_count = 3
    min_count  = 2
    max_count  = 5
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | AKS cluster name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `kubernetes_version` | Kubernetes version | `string` | `"1.30"` | no |
| `node_subnet_id` | Subnet ID for nodes | `string` | — | yes |
| `pod_subnet_id` | Subnet ID for pods (Azure CNI Overlay) | `string` | — | yes |
| `log_analytics_id` | Log Analytics workspace ID | `string` | — | yes |
| `admin_group_object_ids` | AAD group IDs for cluster-admin | `list(string)` | — | yes |
| `default_node_pool` | Default node pool configuration | `object` | — | yes |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | AKS cluster resource ID |
| `cluster_name` | AKS cluster name |
| `kube_config_raw` | Raw kubeconfig (sensitive) |
| `oidc_issuer_url` | OIDC issuer URL for Workload Identity |
