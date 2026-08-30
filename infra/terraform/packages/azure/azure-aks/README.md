# Package: `azure-aks`

An opinionated AKS platform composed from this repository's Azure modules.

Terraform counterpart of [`infra/pulumi/packages/azure/azure-aks`](../../../../pulumi/packages/azure/azure-aks).

## Composition

| Module | Role |
|---|---|
| `modules/azure/resource-group` | Resource group holding every resource in the package |
| `modules/azure/vnet` | Virtual network and its subnets |
| `modules/azure/nsg` | Network security group associated with the node subnet |
| `modules/azure/managed-identity` | User-assigned identity for workload federation |
| `modules/azure/log-analytics` | Workspace wired into the cluster's OMS agent |
| `modules/azure/aks` | Cluster with a system node pool and optional user pools |

The `vnet` module exposes `subnet_ids` as a **map keyed by subnet name**, so the
node subnet is selected by `node_subnet_name` rather than by position. If you
override `subnets`, one of the entries must carry that name.

The cluster uses a **system-assigned** identity. The user-assigned identity this
package creates is exposed for workload federation and role assignments the
consuming root module owns — the package makes no role assignments itself.

## Usage

```hcl
module "platform" {
  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/terraform/packages/azure/azure-aks?ref=v2.0.0"

  project_name = "acme"
  environment  = "prod"
  location     = "eastus"

  address_space = ["10.30.0.0/16"]
  subnets = [
    { name = "nodes", address_prefixes = ["10.30.1.0/24"], service_endpoints = [] }
  ]
  node_subnet_name = "nodes"

  kubernetes_version  = "1.29"
  system_node_count   = 3
  system_node_vm_size = "Standard_D4s_v3"

  user_node_pools = {
    workload = {
      vm_size    = "Standard_D8s_v3"
      node_count = 2
    }
  }

  tags = {
    Owner = "platform-team"
  }
}
```

This package declares no `backend` and no `provider` block — the consuming root
module owns both.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — (required) | Project name used for resource naming and tagging |
| `environment` | `string` | `"dev"` | Deployment environment |
| `location` | `string` | — (required) | Azure region for every resource in the package |
| `resource_group_suffix` | `string` | `"aks"` | Short name appended to the resource group |
| `address_space` | `list(string)` | `["10.0.0.0/16"]` | Address space for the virtual network |
| `subnets` | `list(object)` | one subnet named `nodes` | Subnets to create; must include `node_subnet_name` |
| `node_subnet_name` | `string` | `"nodes"` | Name of the subnet hosting the AKS node pools |
| `security_rules` | `list(object)` | allow-HTTPS + deny-all | NSG rules applied to the node subnet |
| `log_analytics_sku` | `string` | `"PerGB2018"` | Log Analytics workspace SKU |
| `log_retention_in_days` | `number` | `30` | Log Analytics retention in days (30-730) |
| `kubernetes_version` | `string` | `"1.29"` | Kubernetes version for the cluster |
| `system_node_count` | `number` | `2` | Nodes in the system node pool |
| `system_node_vm_size` | `string` | `"Standard_D2s_v3"` | VM size for system node pool nodes |
| `enable_auto_scaling` | `bool` | `false` | Enable the cluster autoscaler on the system pool |
| `min_node_count` | `number` | `1` | Minimum node count when autoscaling is enabled |
| `max_node_count` | `number` | `5` | Maximum node count when autoscaling is enabled |
| `user_node_pools` | `map(object)` | `{}` | Additional user node pools, keyed by pool name |
| `tags` | `map(string)` | `{}` | Additional tags merged onto every resource |

## Outputs

| Name | Description |
|---|---|
| `resource_group_name` | Name of the resource group holding the platform |
| `location` | Azure region the platform was deployed to |
| `vnet_id` | ID of the virtual network |
| `vnet_name` | Name of the virtual network |
| `subnet_ids` | Map of subnet names to subnet IDs |
| `nsg_id` | ID of the network security group applied to the node subnet |
| `identity_id` | Resource ID of the user-assigned managed identity |
| `identity_principal_id` | Service principal (object) ID of the managed identity |
| `identity_client_id` | Client ID of the managed identity |
| `workspace_id` | Log Analytics workspace resource ID |
| `workspace_name` | Log Analytics workspace name |
| `cluster_id` | ID of the AKS cluster |
| `cluster_name` | Name of the AKS cluster |
| `kube_config` | Raw kubeconfig (sensitive) |
| `node_resource_group` | Auto-generated resource group holding AKS node resources |
