# Package: `aws-eks`

An opinionated EKS platform composed from this repository's AWS modules.

Terraform counterpart of [`infra/pulumi/packages/aws/aws-eks`](../../../../pulumi/packages/aws/aws-eks).

## Composition

| Module | Role |
|---|---|
| `modules/aws/vpc` | VPC, public/private subnets across the given AZs, optional NAT Gateway |
| `modules/aws/kms` | Customer-managed key with annual rotation, used by S3 and CloudWatch |
| `modules/aws/s3` | Versioned, SSE-KMS encrypted bucket for platform artifacts |
| `modules/aws/eks` | Control plane and managed node group in the private subnets |
| `modules/aws/cloudwatch` | Encrypted log group and optional metric alarms |

Worker nodes run in the **private** subnets. `enable_nat_gateway` must stay `true`
for them to pull container images.

The `eks` module creates its own cluster and node-group IAM roles and exposes them
as `cluster_role_arn` / `node_group_role_arn`, so this package does **not** compose
`modules/aws/iam-role`.

## Usage

```hcl
module "platform" {
  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/terraform/packages/aws/aws-eks?ref=v2.0.0"

  project_name = "acme"
  environment  = "prod"

  azs                  = ["us-east-1a", "us-east-1b"]
  vpc_cidr             = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

  kubernetes_version = "1.29"
  instance_types     = ["t3.large"]
  desired_size       = 3
  min_size           = 2
  max_size           = 6

  tags = {
    Owner = "platform-team"
  }
}
```

This package declares no `backend` and no `provider` block — the consuming root
module owns both.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `project_name` | `string` | — (required) | Project name used for resource naming and tagging |
| `environment` | `string` | `"dev"` | Deployment environment |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | CIDR block for the VPC |
| `azs` | `list(string)` | `["us-east-1a", "us-east-1b"]` | Availability zones — EKS requires at least two |
| `public_subnet_cidrs` | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | CIDR blocks for public subnets, one per AZ |
| `private_subnet_cidrs` | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | CIDR blocks for private subnets, one per AZ |
| `enable_nat_gateway` | `bool` | `true` | Create a NAT Gateway for private subnet egress |
| `kms_deletion_window_in_days` | `number` | `30` | Days before KMS key deletion takes effect (7-30) |
| `state_bucket_name` | `string` | `null` | Bucket name; `null` yields `<project>-<env>-data` |
| `state_bucket_expiration_days` | `number` | `0` | Object expiry in days (`0` = no lifecycle rule) |
| `kubernetes_version` | `string` | `"1.29"` | Kubernetes control-plane version |
| `endpoint_public_access` | `bool` | `true` | Allow public API server endpoint access |
| `instance_types` | `list(string)` | `["t3.medium"]` | Instance types for the managed node group |
| `capacity_type` | `string` | `"ON_DEMAND"` | `ON_DEMAND` or `SPOT` |
| `desired_size` | `number` | `2` | Desired worker node count |
| `min_size` | `number` | `1` | Minimum worker node count |
| `max_size` | `number` | `4` | Maximum worker node count |
| `log_retention_in_days` | `number` | `30` | CloudWatch retention (`0` = never expire) |
| `metric_alarms` | `list(object)` | `[]` | Metric alarms created alongside the log group |
| `tags` | `map(string)` | `{}` | Additional tags merged onto every resource |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the VPC hosting the cluster |
| `private_subnet_ids` | IDs of the private subnets running the worker nodes |
| `public_subnet_ids` | IDs of the public subnets |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API server endpoint |
| `cluster_ca_certificate` | Base64-encoded cluster CA certificate (sensitive) |
| `kms_key_arn` | ARN of the KMS key encrypting bucket objects and log data |
| `state_bucket_name` | Name of the S3 bucket for platform artifacts |
| `log_group_name` | CloudWatch log group name for the platform |
