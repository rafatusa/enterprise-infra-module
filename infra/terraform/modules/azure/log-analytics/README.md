# Module: azure/log-analytics

Creates a Log Analytics workspace for centralised logging and metrics.

## Usage

```hcl
module "log_analytics" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/log-analytics?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  sku               = "PerGB2018"
  retention_in_days = 90
}
```

Wire it into AKS:

```hcl
module "aks" {
  source                     = ".../modules/azure/aks?ref=v2.0.0"
  log_analytics_workspace_id = module.log_analytics.workspace_id
}
```

## Two different "IDs"

This trips people up, so be explicit:

| Output | What it is | Use for |
|---|---|---|
| `workspace_id` | The full Azure **resource ID** (`/subscriptions/.../workspaces/...`) | Terraform resource references, e.g. AKS OMS agent |
| `workspace_customer_id` | The workspace **GUID** | Agent configuration, the Log Analytics API |

The output names are `primary_shared_key` and `workspace_customer_id` — earlier
documentation called them `workspace_key` and `customer_id`. Neither of those exists.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `resource_group_name` | Resource group for the workspace | `string` | `null` | no |
| `location` | Azure region | `string` | `null` | no |
| `sku` | Log Analytics workspace SKU | `string` | `"PerGB2018"` | no |
| `retention_in_days` | Data retention in days (30–730) | `number` | `30` | no |
| `tags` | Additional tags merged onto the workspace | `map(string)` | `{}` | no |

Although `project_name`, `resource_group_name` and `location` default to `null` so the
module can be planned in isolation, Azure will not create the workspace without them.

## Outputs

| Name | Description |
|---|---|
| `workspace_id` | Log Analytics workspace resource ID |
| `workspace_name` | Log Analytics workspace name |
| `primary_shared_key` | Primary shared key (sensitive) |
| `workspace_customer_id` | Workspace customer ID / GUID (used by agents) |

## Notes

- The workspace is named `<project_name>-<environment>-law`.
- `retention_in_days` below 30 is only valid on the `Free` SKU, which is retired for new
  workspaces. Keep it at 30 or above on `PerGB2018`.
- `primary_shared_key` is marked sensitive. Never write it into a file or log; pass it
  through a secret store.
- Deleting a workspace soft-deletes it for 14 days. Re-creating one with the same name
  inside that window recovers the old workspace rather than making a fresh one.
