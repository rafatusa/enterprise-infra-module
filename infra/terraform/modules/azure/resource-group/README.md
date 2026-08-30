# Module: azure/resource-group

Creates an Azure Resource Group — the logical container for all other Azure resources in a deployment.

## Usage

```hcl
module "resource_group" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/resource-group?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  location     = "eastus"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `location` | Azure region (e.g. `eastus`, `westeurope`) | `string` | — | yes |

## Outputs

| Name | Description |
|---|---|
| `name` | Name of the resource group |
| `id` | Resource ID of the resource group |
| `location` | Location of the resource group |
