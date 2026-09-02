# Module: azure/managed-identity

Creates a user-assigned managed identity and exports the identifiers needed to attach it
to other Azure resources.

> **This module does not assign RBAC roles.** Earlier documentation advertised a
> `role_assignments` input and claimed the module "optionally assigns Azure RBAC roles".
> No such variable exists and no `azurerm_role_assignment` resource is created. Assign
> roles yourself using the `principal_id` output — see below.

## Usage

```hcl
module "app_identity" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/managed-identity?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  identity_name       = "app"
  resource_group_name = module.resource_group.resource_group_name
  location            = "eastus"
}
```

## Assigning roles

Use the `principal_id` output with `azurerm_role_assignment` in your own configuration:

```hcl
resource "azurerm_role_assignment" "blob_reader" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.app_identity.principal_id
}
```

## Attaching the identity

```hcl
resource "azurerm_linux_virtual_machine" "app" {
  # ...
  identity {
    type         = "UserAssigned"
    identity_ids = [module.app_identity.identity_id]
  }
}
```

## Resource naming

The identity is named `<project_name>-<environment>-<identity_name>-identity`.
`identity_name` is a short label, not the full resource name.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | `null` | no |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `identity_name` | Short name for the managed identity (e.g. `app`, `aks`) | `string` | `"app"` | no |
| `resource_group_name` | Resource group to create the identity in | `string` | `null` | no |
| `location` | Azure region | `string` | `null` | no |
| `tags` | Additional tags merged into the resource | `map(string)` | `{}` | no |

Although `project_name`, `resource_group_name` and `location` default to `null` so the
module can be planned in isolation, Azure will not create the identity without them.
Treat them as effectively required.

## Outputs

| Name | Description |
|---|---|
| `identity_id` | Managed identity resource ID (use for `identity_ids`) |
| `principal_id` | Service principal / object ID (use for role assignments) |
| `client_id` | Client ID of the managed identity |
| `tenant_id` | Tenant ID of the managed identity |
