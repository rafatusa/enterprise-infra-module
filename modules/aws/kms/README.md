# Module: aws/kms

Creates an AWS KMS Customer Managed Key (CMK) with alias, optional key rotation, multi-region support, and a least-privilege key policy.

## Usage

```hcl
module "kms" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/aws/kms?ref=v1.0.0"

  name        = "my-app-eks"
  description = "KMS key for EKS secrets encryption"
  project     = "my-project"
  environment = "production"

  enable_key_rotation = true
  key_users           = [module.eks_cluster_role.role_arn]
}
```
