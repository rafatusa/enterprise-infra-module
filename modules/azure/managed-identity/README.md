# azure/managed-identity

Provisions a User-Assigned Managed Identity and optional Azure RBAC role assignments.

## Usage

```hcl
module "identity" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/managed-identity?ref=v1.1.0"

  name                = "my-project-identity"
  project             = "my-project"
  environment         = "production"
  resource_group_name = module.rg.name
  location            = module.rg.location

  role_assignments = [
    {
      scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${module.rg.name}"
      role_definition_name = "Contributor"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Managed identity name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `resource_group_name` | Resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `role_assignments` | List of `{scope, role_definition_name}` objects | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Managed identity resource ID |
| `principal_id` | Service principal (object) ID |
| `client_id` | Client ID |
| `tenant_id` | Tenant ID |
