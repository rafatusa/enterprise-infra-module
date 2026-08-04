# Module: azure/managed-identity

Creates a **User Assigned Managed Identity** with optional RBAC role assignments.

Use this module to give Azure workloads (AKS, App Service, VMs) an identity
without managing credentials — assign roles via `role_assignments` input.

## Usage

```hcl
module "identity" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/azure/managed-identity?ref=v1.1.0"

  name                = "my-aks-identity"
  resource_group_name = module.rg.name
  location            = "eastus"

  role_assignments = [
    {
      role_definition_name = "AcrPull"
      scope                = azurerm_container_registry.acr.id
    }
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the managed identity | `string` | — | yes |
| resource_group_name | Resource group to deploy into | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| role_assignments | List of role assignments to create | `list(object)` | `[]` | no |
| tags | Tags to apply to the identity | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the identity |
| `name` | Name of the identity |
| `principal_id` | Principal (object) ID — used for RBAC |
| `client_id` | Client ID — used by workloads |
| `tenant_id` | Tenant ID |
