# azure/log-analytics

Provisions an Azure Log Analytics Workspace and the Container Insights solution for AKS monitoring.

## Usage

```hcl
module "log_analytics" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/log-analytics?ref=v1.1.0"

  name                = "my-project-law"
  project             = "my-project"
  environment         = "production"
  resource_group_name = module.rg.name
  location            = module.rg.location

  retention_in_days        = 30
  enable_container_insights = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Workspace name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `retention_in_days` | Log retention in days | `number` | `30` | no |
| `enable_container_insights` | Deploy Container Insights solution | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `workspace_id` | Log Analytics Workspace resource ID |
| `workspace_name` | Workspace name |
| `customer_id` | Workspace GUID (used for agent onboarding) |
