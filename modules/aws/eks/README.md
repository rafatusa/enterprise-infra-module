# Module: aws/eks

Creates an AWS EKS cluster with managed node groups, CloudWatch control plane logging, OIDC provider for IRSA, and optional KMS encryption for Kubernetes secrets.

**Note:** This module expects pre-created IAM roles. Use the `aws/iam-role` module and the `packages/aws-eks` package for a complete, dependency-resolved environment.

## Usage

```hcl
module "eks" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/aws/eks?ref=v1.0.0"

  cluster_name      = "my-app-eks"
  kubernetes_version = "1.33"
  project           = "my-project"
  environment       = "production"

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

## Security Notes

- All control plane log types are enabled by default (`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`).
- Kubernetes secrets are encrypted via KMS when `kms_key_arn` is provided.
- OIDC provider is created to enable IAM Roles for Service Accounts (IRSA).
- Node groups run in private subnets only.
- `desired_size` changes by the cluster-autoscaler are ignored on subsequent applies.
