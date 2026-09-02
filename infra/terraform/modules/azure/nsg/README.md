# Module: azure/nsg

Creates a network security group, its rules, and optionally associates it with subnets.

## Usage

```hcl
module "nsg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/nsg?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  subnet_ids = [module.vnet.subnet_ids["app"]]
}
```

## The default rules are restrictive

`security_rules` does **not** default to an empty list. Omitting it gives you two
inbound rules:

| Priority | Name | Effect |
|---|---|---|
| 100 | `allow-https-inbound` | Allow TCP 443 from `Internet` |
| 4096 | `deny-all-inbound` | Deny everything else inbound |

So the default posture is "HTTPS only, nothing else in". This is usually what you want,
but it will silently block SSH, HTTP on port 80, and any application port unless you
supply your own rules. Earlier documentation claimed the default was `[]`, which would
have left Azure's own defaults in place — a materially different, more permissive
posture.

To open additional ports, pass the full list including the rules you want to keep:

```hcl
security_rules = [
  {
    name                       = "allow-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Allow HTTPS inbound"
  },
  {
    name                       = "allow-ssh-from-office"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "203.0.113.0/24"
    destination_address_prefix = "*"
  },
  {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
]
```

Rules are keyed by `name`, so every name in the list must be unique. `description` is the
only optional field; all others are required on each object.

## Subnet association

`subnet_ids` takes a **list** of subnet IDs. The `azure/vnet` module exports
`subnet_ids` as a map keyed by name, so index it:

```hcl
subnet_ids = [module.vnet.subnet_ids["app"]]
```

Leaving `subnet_ids` empty creates the NSG and its rules without attaching them to
anything.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `resource_group_name` | Name of the resource group to deploy into | `string` | `null` | no |
| `location` | Azure region for the NSG | `string` | `null` | no |
| `subnet_ids` | Subnet IDs to associate with this NSG | `list(string)` | `[]` | no |
| `security_rules` | Security rule objects (see above) | `list(object(...))` | allow-HTTPS + deny-all | no |
| `tags` | Additional tags applied to the NSG | `map(string)` | `{}` | no |

This module takes `subnet_ids` (a list), not `subnet_id`. Although `project_name`,
`resource_group_name` and `location` default to `null` so the module can be planned in
isolation, the NSG cannot be created without them.

## Outputs

| Name | Description |
|---|---|
| `nsg_id` | The ID of the network security group |
| `nsg_name` | The name of the network security group |

## Notes

- The NSG is named `<project_name>-<environment>-nsg`. Rules keep the exact `name` you
  supply.
- A subnet can only be associated with one NSG. Associating a second replaces the first.
- Azure rule priorities must be between 100 and 4096 and unique per direction.
