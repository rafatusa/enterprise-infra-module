# Module: azure/nsg

Creates an Azure Network Security Group with configurable inbound/outbound rules and optional subnet association.

## Usage

```hcl
module "nsg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/nsg?ref=v1.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.name
  location            = "eastus"
  security_rules = [
    {
      name                       = "allow-https"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `resource_group_name` | Resource group to create the NSG in | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `security_rules` | List of security rule objects | `list(object)` | `[]` | no |
| `subnet_ids` | Subnet IDs to associate the NSG with | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|---|---|
| `nsg_id` | Resource ID of the NSG |
| `nsg_name` | Name of the NSG |
