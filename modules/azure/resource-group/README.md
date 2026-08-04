# Module: azure/resource-group

Creates an Azure Resource Group with enforced standard tags (`Project`, `Environment`, `ManagedBy`, `Module`).

## Usage

```hcl
module "rg" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/azure/resource-group?ref=v1.1.0"

  name        = "myapp-production-rg"
  location    = "eastus"
  project     = "myapp"
  environment = "production"
  tags        = { CostCenter = "platform" }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Resource Group name | `string` | — | yes |
| location | Azure region | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| enable_delete_lock | Prevent accidental deletion | `bool` | `false` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `name` | Resource Group name |
| `location` | Azure region |
| `id` | Resource Group resource ID |
