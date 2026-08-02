# Module: azure/nsg

Creates an Azure Network Security Group with configurable rules and optional subnet associations.

## Usage

```hcl
module "nsg" {
  source = "github.com/org/terraform-enterprise-modules//modules/azure/nsg?ref=v1.0.0"

  name                = "aks-nsg"
  resource_group_name = module.rg.name
  location            = "eastus"
  project             = "myapp"
  environment         = "production"
  subnet_ids          = [module.vnet.subnet_ids["aks-system"]]

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
|------|-------------|------|---------|----------|
| name | NSG name | `string` | — | yes |
| resource_group_name | Resource Group name | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| security_rules | Security rule list | `list(object)` | `[]` | no |
| subnet_ids | Subnets to associate | `list(string)` | `[]` | no |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `"production"` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| nsg_id | NSG resource ID |
| nsg_name | NSG name |
