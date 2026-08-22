# Module: azure/aks

Provisions an AKS cluster with a system node pool and an optional user node pool, integrated with a Log Analytics workspace for monitoring.

## Usage

```hcl
module "aks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/aks?ref=v1.0.0"

  project_name                = "my-app"
  environment                 = "prod"
  resource_group_name         = module.resource_group.name
  location                    = "eastus"
  kubernetes_version          = "1.29"
  system_node_count           = 2
  system_vm_size              = "Standard_D2s_v3"
  log_analytics_workspace_id  = module.log_analytics.workspace_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `resource_group_name` | Resource group to deploy into | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `kubernetes_version` | Kubernetes version | `string` | `"1.29"` | no |
| `system_node_count` | Node count for the system node pool | `number` | `2` | no |
| `system_vm_size` | VM size for system nodes | `string` | `"Standard_D2s_v3"` | no |
| `log_analytics_workspace_id` | Log Analytics workspace ID for Container Insights | `string` | `""` | no |
| `user_node_pool` | Optional user node pool configuration object | `object` | `null` | no |
| `managed_identity_id` | User-assigned managed identity ID | `string` | `""` | no |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | Resource ID of the AKS cluster |
| `cluster_name` | Name of the AKS cluster |
| `kube_config` | Raw kubeconfig (sensitive) |
| `host` | Kubernetes API server host |
| `client_certificate` | Client certificate for authentication |
| `cluster_ca_certificate` | CA certificate of the cluster |
