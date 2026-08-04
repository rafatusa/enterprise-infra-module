# azure/nsg

Provisions an Azure Network Security Group with configurable inbound/outbound security rules and optional subnet associations.

## Usage

```hcl
module "nsg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/nsg?ref=v1.1.0"

  name                = "my-project-nsg"
  project             = "my-project"
  environment         = "production"
  resource_group_name = module.rg.name
  location            = module.rg.location

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

  subnet_ids = [module.vnet.subnet_ids["aks-nodes"]]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | NSG name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `security_rules` | List of security rule objects | `list(object)` | `[]` | no |
| `subnet_ids` | Subnet IDs to associate the NSG with | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `nsg_id` | NSG resource ID |
| `nsg_name` | NSG name |
