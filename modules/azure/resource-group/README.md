# azure/resource-group

Provisions an Azure Resource Group with consistent tagging and an optional management lock to prevent accidental deletion.

## Usage

```hcl
module "rg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/azure/resource-group?ref=v1.1.0"

  name        = "my-project-rg"
  project     = "my-project"
  environment = "production"
  location    = "eastus"
  enable_lock = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource group name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `enable_lock` | Add a CanNotDelete management lock | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `name` | Resource group name |
| `id` | Resource group ID |
| `location` | Azure region |
