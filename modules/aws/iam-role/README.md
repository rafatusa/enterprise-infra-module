# Module: aws/iam-role

Creates an AWS IAM Role with configurable trust policy principals, optional managed policy attachments, optional inline policy, and an EC2 instance profile when `ec2.amazonaws.com` is a principal.

## Usage

```hcl
module "eks_node_role" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/iam-role?ref=v1.1.0"

  name    = "my-app-eks-node-role"
  project = "my-project"

  assume_role_principals = ["ec2.amazonaws.com"]
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}
```

```hcl
# IRSA role (Kubernetes service account trust)
module "app_role" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/iam-role?ref=v1.1.0"

  name    = "my-app-irsa-role"
  project = "my-project"

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  service_account_namespace = "default"
  service_account_name      = "my-app"

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | IAM role name | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| assume_role_principals | Service principals for trust | `list(string)` | `[]` | no |
| oidc_provider_arn | OIDC provider ARN (IRSA) | `string` | `null` | no |
| oidc_provider_url | OIDC issuer URL (IRSA) | `string` | `null` | no |
| service_account_namespace | K8s namespace (IRSA) | `string` | `null` | no |
| service_account_name | K8s service account (IRSA) | `string` | `null` | no |
| managed_policy_arns | Managed policies to attach | `list(string)` | `[]` | no |
| inline_policy_json | Inline policy document JSON | `string` | `null` | no |
| environment | Environment tag | `string` | `production` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | IAM role ARN |
| `role_name` | IAM role name |
| `instance_profile_arn` | Instance profile ARN (EC2 only) |
| `instance_profile_name` | Instance profile name (EC2 only) |
