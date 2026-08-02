# Module: azure/vnet

Creates an Azure Virtual Network with configurable subnets, DNS servers, service endpoints, and subnet delegations.

## Usage

```hcl
module "vnet" {
  source = "github.com/org/terraform-enterprise-modules//modules/azure/vnet?ref=v1.0.0"

  name                = "myapp-vnet"
  resource_group_name = module.rg.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  project             = "myapp"
  environment         = "production"

  subnets = {
    "aks-system" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
    "aks-user" = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | VNet name | `string` | — | yes |
| resource_group_name | Resource Group name | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| address_space | VNet CIDR blocks | `list(string)` | `["10.0.0.0/16"]` | no |
| dns_servers | Custom DNS servers | `list(string)` | `[]` | no |
| subnets | Subnet definitions map | `map(object)` | `{}` | no |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `"production"` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | VNet resource ID |
| vnet_name | VNet name |
| subnet_ids | Map of subnet name → ID |
| subnet_address_prefixes | Map of subnet name → address prefixes |
