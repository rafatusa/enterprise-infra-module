# package: aws-eks

**Production-ready AWS EKS environment** — a single module reference that
automatically provisions the full stack:

| Layer | Resources |
|-------|-----------|
| **Network** | VPC, public + private subnets, Internet Gateway, NAT Gateway (one per AZ), route tables |
| **Security** | Cluster security group, KMS key (secret envelope encryption) |
| **IAM** | EKS cluster service role, managed node group role |
| **Compute** | EKS cluster, managed node groups (configurable, multi-AZ) |
| **Observability** | CloudWatch log group, all control-plane log types enabled |

## Usage

```hcl
module "eks_env" {
  source = "github.com/your-org/terraform-enterprise-modules//packages/aws-eks?ref=v1.0.0"

  cluster_name    = "platform-eks"
  cluster_version = "1.29"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 3
      max_size       = 5
      labels         = { role = "system" }
    }
    apps = {
      instance_types = ["m5.xlarge"]
      desired_size   = 3
      min_size       = 1
      max_size       = 20
      labels         = { role = "apps" }
    }
  }

  log_retention_days = 90

  tags = {
    Project     = "platform"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Consume outputs for app modules:
output "kubeconfig_endpoint" {
  value = module.eks_env.cluster_endpoint
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Cluster name (resource prefix) | `string` | — | yes |
| cluster_version | Kubernetes version | `string` | `1.29` | no |
| vpc_cidr | VPC CIDR | `string` | `10.0.0.0/16` | no |
| availability_zones | AZs for subnets | `list(string)` | — | yes |
| public_subnet_cidrs | Public subnet CIDRs | `list(string)` | — | yes |
| private_subnet_cidrs | Private subnet CIDRs | `list(string)` | — | yes |
| single_nat_gateway | One NAT GW instead of per-AZ | `bool` | `false` | no |
| endpoint_public_access | Public API server | `bool` | `false` | no |
| node_groups | Node group map | `map(object)` | `{general={…}}` | no |
| kms_deletion_window | KMS deletion window (days) | `number` | `30` | no |
| log_retention_days | CloudWatch retention | `number` | `90` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

`vpc_id`, `private_subnet_ids`, `public_subnet_ids`,
`cluster_id`, `cluster_name`, `cluster_endpoint`, `cluster_ca_certificate`,
`oidc_provider_arn`, `oidc_provider_url`,
`cluster_role_arn`, `node_role_arn`,
`kms_key_arn`, `kms_key_id`,
`cloudwatch_log_group_name`

## Security defaults

- API server is **private-only** by default (`endpoint_public_access = false`)
- Secrets encrypted with a **customer-managed KMS key** (rotation enabled)
- All control-plane log types shipped to CloudWatch
- Nodes run in **private subnets only**; outbound via NAT Gateway
- Node IAM role follows least-privilege (EKS worker + CNI + ECR read-only)
