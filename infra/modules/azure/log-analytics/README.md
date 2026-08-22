# Module: azure/log-analytics

Creates an Azure Log Analytics workspace for collecting logs and metrics from AKS, VMs, and other Azure services.

## Usage

```hcl
module "log_analytics" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/log-analytics?ref=v1.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.name
  location            = "eastus"
  retention_in_days   = 90
  sku                 = "PerGB2018"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `resource_group_name` | Resource group for the workspace | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `retention_in_days` | Data retention period in days | `number` | `30` | no |
| `sku` | Pricing tier (`PerGB2018` recommended) | `string` | `"PerGB2018"` | no |

## Outputs

| Name | Description |
|---|---|
| `workspace_id` | Resource ID of the Log Analytics workspace |
| `workspace_key` | Primary shared key (sensitive) |
| `workspace_name` | Name of the workspace |
| `customer_id` | Workspace GUID used as the Log Analytics customer ID |
