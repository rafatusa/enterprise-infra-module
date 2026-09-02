# Module: azure/vnet

Creates an Azure virtual network with a configurable set of subnets.

## Usage

```hcl
module "vnet" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/vnet?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location

  address_space = ["10.0.0.0/16"]

  subnets = [
    {
      name              = "app"
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    },
    {
      name             = "data"
      address_prefixes = ["10.0.2.0/24"]
    },
  ]
}
```

## `subnets` is a list of objects

The type is:

```hcl
list(object({
  name              = string
  address_prefixes  = list(string)
  service_endpoints = optional(list(string), [])
}))
```

Earlier documentation described `subnets` as `map(string)`. Passing a map is a **type
error**, not a naming mismatch — Terraform rejects it at plan time.

`address_prefixes` is a list even for a single CIDR. `service_endpoints` is optional and
defaults to `[]`.

The default value creates two subnets, `public` (`10.0.1.0/24`) and `private`
(`10.0.2.0/24`). Pass your own list to override.

## `subnet_ids` is a map, not a list

The `subnet_ids` output is keyed by subnet **name**:

```hcl
subnet_id = module.vnet.subnet_ids["app"]
```

Indexing it positionally (`[0]`) does not work. Use `subnet_names` if you need the
ordered set of keys.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `resource_group_name` | Name of the resource group to deploy into | `string` | `null` | no |
| `location` | Azure region for the virtual network | `string` | `null` | no |
| `address_space` | Address space for the virtual network (CIDR blocks) | `list(string)` | `["10.0.0.0/16"]` | no |
| `subnets` | Subnet objects to create (see above) | `list(object(...))` | two subnets, `public` + `private` | no |
| `tags` | Additional tags applied to the virtual network | `map(string)` | `{}` | no |

Pass `resource_group_name`, not `module.resource_group.name` — that output does not
exist. Although `project_name`, `resource_group_name` and `location` default to `null` so
the module can be planned in isolation, the network cannot be created without them.

## Outputs

| Name | Description |
|---|---|
| `vnet_id` | The ID of the virtual network |
| `vnet_name` | The name of the virtual network |
| `subnet_ids` | **Map** of subnet name to subnet ID |
| `subnet_names` | List of subnet names |

## Notes

- The virtual network is named `<project_name>-<environment>-vnet`. Subnets keep the
  exact `name` you supply, unprefixed.
- Subnet address prefixes must fall inside `address_space`.
- Tags apply to the virtual network only; Azure subnets do not support tags.
- This module does not create NSGs or associate them. Use `azure/nsg`, which takes
  `subnet_ids` and performs the association.
