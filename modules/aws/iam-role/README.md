# aws/iam-role

Provisions an IAM Role with a configurable trust policy, inline/managed policy attachments, and an optional EC2 instance profile.

## Usage

### EC2 instance role

```hcl
module "app_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/iam-role?ref=v1.1.0"

  name        = "my-project-app"
  project     = "my-project"
  environment = "production"

  assume_role_principals = ["ec2.amazonaws.com"]
  create_instance_profile = true
}
```

### IRSA (IAM Role for Service Account)

```hcl
module "irsa_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/iam-role?ref=v1.1.0"

  name        = "my-sa-role"
  project     = "my-project"
  environment = "production"

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  service_account   = "my-namespace/my-service-account"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Role name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `assume_role_principals` | List of service principals for trust policy | `list(string)` | `[]` | no |
| `create_instance_profile` | Create an EC2 instance profile | `bool` | `false` | no |
| `oidc_provider_arn` | OIDC provider ARN (for IRSA) | `string` | `""` | no |
| `oidc_provider_url` | OIDC provider URL (for IRSA) | `string` | `""` | no |
| `service_account` | `namespace/name` of the k8s service account | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | IAM role ARN |
| `role_name` | IAM role name |
| `instance_profile_arn` | Instance profile ARN (if created) |
