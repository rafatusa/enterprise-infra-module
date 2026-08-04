# azure/vnet

Provisions an Azure Virtual Network with configurable subnets, service endpoints, and optional DDoS protection.

## Usage

```hcl
module "vnet" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/vnet?ref=v1.1.0"

  name                = "my-project-vnet"
  project             = "my-project"
  environment         = "production"
  resource_group_name = module.rg.name
  location            = module.rg.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    aks-nodes = { cidr = "10.0.1.0/24", service_endpoints = ["Microsoft.Storage"] }
    aks-pods  = { cidr = "10.0.2.0/24", service_endpoints = [] }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | VNet name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `address_space` | VNet address space | `list(string)` | — | yes |
| `subnets` | Map of subnet name → `{cidr, service_endpoints}` | `map(object)` | — | yes |
| `enable_ddos_protection` | Enable DDoS Protection Standard | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | VNet resource ID |
| `vnet_name` | VNet name |
| `subnet_ids` | Map of subnet name → subnet ID |
