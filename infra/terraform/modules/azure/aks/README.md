# Module: azure/aks

Creates an AKS cluster with a system node pool, Azure CNI networking, Azure network
policy, RBAC, and optional user node pools.

## Usage

```hcl
module "aks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/aks?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  # Azure CNI requires a subnet.
  subnet_id = module.vnet.subnet_ids["app"]

  kubernetes_version  = "1.29"
  system_node_count   = 3
  system_node_vm_size = "Standard_D2s_v3"

  log_analytics_workspace_id = module.log_analytics.workspace_id
}
```

## Identity is SystemAssigned

The cluster always uses a **system-assigned** managed identity. There is no
`managed_identity_id` input and you cannot supply a user-assigned identity. To grant the
cluster permissions, use the `cluster_identity` output:

```hcl
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.cluster_identity.principal_id
}
```

## Networking

`network_plugin` is hardcoded to `azure` (Azure CNI), which means **every pod takes an IP
from the subnet**. Size `subnet_id` accordingly — a `/24` supports far fewer pods than
you might expect. `network_policy` is `azure` and `load_balancer_sku` is `standard`.

`dns_prefix` is derived as `<project_name>-<environment>` and is not an input.

## Autoscaling

Autoscaling on the system pool is **off** by default. Enable it explicitly:

```hcl
enable_auto_scaling = true
min_node_count      = 2
max_node_count      = 10
```

`min_node_count` and `max_node_count` are ignored unless `enable_auto_scaling` is `true`.

Note that `node_count` on the system pool carries `ignore_changes`, so manual or
autoscaler-driven scaling is not reverted by a subsequent apply.

## User node pools

`user_node_pools` is a **map** keyed by pool name, not a single object:

```hcl
user_node_pools = {
  workers = {
    vm_size    = "Standard_D4s_v3"
    node_count = 2
  }
  spot = {
    vm_size             = "Standard_D4s_v3"
    node_count          = 1
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 5
  }
}
```

`vm_size` and `node_count` are required per pool; the autoscaling fields are optional.
All user pools share the cluster's `subnet_id`.

## Connecting

```bash
az aks get-credentials --resource-group <rg> --name <cluster_name>
```

Or use the `kube_config` output directly — it is the raw kubeconfig and is marked
sensitive.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `resource_group_name` | Name of the resource group to deploy into | `string` | `null` | no |
| `location` | Azure region for the AKS cluster | `string` | `null` | no |
| `subnet_id` | Subnet ID for the node pools | `string` | `null` | no |
| `kubernetes_version` | Kubernetes version for the cluster | `string` | `"1.29"` | no |
| `system_node_count` | Number of nodes in the system node pool | `number` | `2` | no |
| `system_node_vm_size` | VM size for system node pool nodes | `string` | `"Standard_D2s_v3"` | no |
| `enable_auto_scaling` | Enable cluster autoscaler on the system node pool | `bool` | `false` | no |
| `min_node_count` | Minimum node count when autoscaling is enabled | `number` | `1` | no |
| `max_node_count` | Maximum node count when autoscaling is enabled | `number` | `5` | no |
| `user_node_pools` | Map of additional user node pool configurations (see above) | `map(object(...))` | `{}` | no |
| `log_analytics_workspace_id` | Log Analytics workspace **resource ID** for the OMS agent (`null` disables) | `string` | `null` | no |
| `tags` | Additional tags applied to the cluster and user pools | `map(string)` | `{}` | no |

The VM size variable is `system_node_vm_size`, not `system_vm_size`. Although
`project_name`, `resource_group_name`, `location` and `subnet_id` default to `null` so
the module can be planned in isolation, the cluster cannot be created without them.

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | The ID of the AKS cluster |
| `cluster_name` | The name of the AKS cluster |
| `kube_config` | Raw kubeconfig (sensitive) |
| `kube_config_host` | Kubernetes API server host (sensitive) |
| `cluster_identity` | The system-assigned identity object (has `principal_id`, `tenant_id`) |
| `node_resource_group` | Auto-generated resource group holding AKS node resources |

There are no `host`, `client_certificate` or `cluster_ca_certificate` outputs. Use
`kube_config` if you need credentials.

## Notes

- The cluster is named `<project_name>-<environment>-aks`.
- OS disk size is hardcoded to 128 GB on all pools.
- AKS creates a second resource group (`node_resource_group`) for node infrastructure.
  Do not manage its contents directly.
- `log_analytics_workspace_id` takes the workspace **resource ID**
  (`module.log_analytics.workspace_id`), not the customer GUID.
