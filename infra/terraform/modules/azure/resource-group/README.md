# Module: azure/resource-group

Creates an Azure resource group with consistent naming and tagging.

## Usage

```hcl
module "resource_group" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/resource-group?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  name         = "app"
  location     = "eastus"
}
```

Creates a resource group named `my-app-prod-app-rg`.

## Resource naming

The group is named `<project_name>-<environment>-<name>-rg`. `name` is a short label
(e.g. `app`, `shared`, `data`), not the full resource group name.

## Consuming the outputs

Downstream modules take the **name**, not the ID:

```hcl
module "vnet" {
  source              = ".../modules/azure/vnet?ref=v2.0.0"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
}
```

The outputs are `resource_group_name` and `resource_group_id` — not `name` and `id`.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `name` | Short name appended to the resource group (e.g. `app`, `shared`, `data`) | `string` | `"app"` | no |
| `location` | Azure region (e.g. `eastus`, `westeurope`) | `string` | `null` | no |
| `tags` | Additional tags merged onto the resource group | `map(string)` | `{}` | no |

Although `project_name` and `location` default to `null` so the module can be planned in
isolation, Azure will not create the group without them. Treat them as effectively
required.

## Outputs

| Name | Description |
|---|---|
| `resource_group_id` | Resource group ID |
| `resource_group_name` | Resource group name |
| `location` | Resource group location |

## Notes

- Deleting a resource group deletes everything inside it. Terraform will refuse if other
  resources it does not manage still exist in the group.
- Azure resource group names allow up to 90 characters; keep `project_name` short enough
  that the composed name fits.
