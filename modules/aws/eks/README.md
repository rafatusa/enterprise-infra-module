# aws/eks

Provisions an EKS cluster with managed node groups, OIDC provider for IRSA, and KMS envelope encryption for Kubernetes secrets.

## Usage

```hcl
module "eks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/eks?ref=v1.1.0"

  cluster_name       = "my-cluster"
  project            = "my-project"
  environment        = "production"
  subnet_ids         = module.vpc.private_subnet_ids
  kubernetes_version = "1.30"

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }
}
```

## IRSA (IAM Roles for Service Accounts)

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
| `cluster_name` | EKS cluster name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `subnet_ids` | Subnet IDs for the cluster | `list(string)` | — | yes |
| `kubernetes_version` | Kubernetes version | `string` | `"1.30"` | no |
| `node_groups` | Map of managed node group configurations | `map(object)` | — | yes |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | API server endpoint |
| `cluster_ca_certificate` | Base64-encoded cluster CA |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `oidc_provider_url` | OIDC provider URL |
