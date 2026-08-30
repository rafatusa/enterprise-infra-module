# Module: azure/vnet

Creates an Azure Virtual Network with configurable subnets.

## Usage

```hcl
module "vnet" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/vnet?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    "aks-system" = "10.0.1.0/24"
    "aks-user"   = "10.0.2.0/24"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `resource_group_name` | Name of the resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `address_space` | Address space CIDR blocks for the VNet | `list(string)` | `["10.0.0.0/16"]` | no |
| `subnets` | Map of subnet name → CIDR block | `map(string)` | — | yes |

## Outputs

| Name | Description |
|---|---|
| `vnet_id` | Resource ID of the Virtual Network |
| `vnet_name` | Name of the Virtual Network |
| `subnet_ids` | Map of subnet name → subnet ID |
