# Module: aws/eks

Creates an AWS EKS cluster with managed node groups, CloudWatch control plane logging, OIDC provider for IRSA, and optional KMS encryption for Kubernetes secrets.

**Note:** This module expects pre-created IAM roles. Use the `aws/iam-role` module and the `packages/aws-eks` package for a complete, dependency-resolved environment.

## Usage

```hcl
module "eks" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/eks?ref=v1.1.0"

  cluster_name       = "my-app-eks"
  kubernetes_version = "1.33"
  project            = "my-project"
  environment        = "production"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_role_arn   = module.cluster_role.role_arn
  node_role_arn      = module.node_role.role_arn
  kms_key_arn        = module.kms.key_arn

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 5
    }
    workload = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      labels         = { role = "workload" }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name | `string` | — | yes |
| kubernetes_version | Kubernetes version | `string` | `1.29` | no |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| vpc_id | VPC ID | `string` | — | yes |
| private_subnet_ids | Private subnet IDs | `list(string)` | — | yes |
| cluster_role_arn | EKS cluster service role ARN | `string` | — | yes |
| node_role_arn | Node group IAM role ARN | `string` | — | yes |
| kms_key_arn | KMS key ARN for secrets encryption | `string` | `null` | no |
| node_groups | Node group definitions | `map(object)` | `{general={…}}` | no |
| log_retention_days | CloudWatch log retention | `number` | `90` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | API server endpoint |
| `cluster_ca_certificate` | CA certificate (base64) |
| `cluster_arn` | Cluster ARN |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `oidc_provider_url` | OIDC issuer URL |

## Security Notes

- All control plane log types are enabled by default (`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`).
- Kubernetes secrets are encrypted via KMS when `kms_key_arn` is provided.
- OIDC provider is created to enable IAM Roles for Service Accounts (IRSA).
- Node groups run in private subnets only.
- `desired_size` changes by the cluster-autoscaler are ignored on subsequent applies.
