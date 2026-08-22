# Module: azure/managed-identity

Creates a user-assigned managed identity and optionally assigns Azure RBAC roles to it.

## Usage

```hcl
module "managed_identity" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/managed-identity?ref=v1.0.0"

  project_name        = "my-app"
  environment         = "prod"
  resource_group_name = module.resource_group.name
  location            = "eastus"
  role_assignments = [
    {
      scope                = "/subscriptions/<subscription-id>"
      role_definition_name = "AcrPull"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `resource_group_name` | Resource group for the identity | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `role_assignments` | List of role assignment objects (scope + role_definition_name) | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|---|---|
| `identity_id` | Resource ID of the managed identity |
| `principal_id` | Object ID (principal ID) for role assignments |
| `client_id` | Client ID for workload identity federation |
