# azure/log-analytics

Creates an **Azure Log Analytics Workspace** with optional solutions for
Container Insights (AKS) and VM Insights.

## Usage

```hcl
module "logs" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/azure/log-analytics?ref=v1.0.0"

  name                      = "platform-logs"
  resource_group_name       = module.rg.name
  location                  = "eastus"
  retention_in_days         = 90
  enable_container_insights = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Workspace name | `string` | — | yes |
| resource_group_name | Resource group | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| sku | Pricing SKU | `string` | `PerGB2018` | no |
| retention_in_days | Log retention (30-730 days) | `number` | `90` | no |
| daily_quota_gb | Ingestion cap in GB (-1 = unlimited) | `number` | `-1` | no |
| internet_ingestion_enabled | Allow public ingestion | `bool` | `true` | no |
| internet_query_enabled | Allow public queries | `bool` | `true` | no |
| local_authentication_disabled | Force AAD-only auth | `bool` | `false` | no |
| enable_container_insights | Deploy ContainerInsights solution | `bool` | `false` | no |
| enable_vm_insights | Deploy VMInsights solution | `bool` | `false` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID |
| name | Workspace name |
| workspace_id | Globally unique workspace ID |
| primary_shared_key | Primary ingestion key (sensitive) |
| secondary_shared_key | Secondary ingestion key (sensitive) |
