# aws-eks package

A solution package that composes all 9 AWS modules into a complete, production-ready EKS environment in the correct dependency order.

## What it provisions

| Module | Resource |
|--------|----------|
| `aws/kms` | KMS CMK for EKS secrets + EBS encryption |
| `aws/vpc` | VPC, public/private subnets, NAT gateways |
| `aws/security-group` | Cluster and node security groups |
| `aws/iam-role` | EKS cluster role + node group role |
| `aws/eks` | EKS control plane + managed node groups + OIDC |
| `aws/s3` | Artifact/config bucket (KMS-encrypted) |
| `aws/rds` | Optional RDS PostgreSQL (disabled by default) |
| `aws/cloudwatch` | Log group + CPU alarms + dashboard |

## Usage

```hcl
module "eks_env" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/packages/aws-eks?ref=v1.1.0"

  cluster_name = var.cluster_name
  environment  = "production"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 5
    }
  }

  tags = {
    Project     = var.cluster_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

output "cluster_endpoint" { value = module.eks_env.cluster_endpoint }
output "vpc_id"           { value = module.eks_env.vpc_id }
```

## GitHub Actions pipeline

```yaml
- uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "1.7.0"

- name: Terraform init
  run: |
    terraform init -input=false -reconfigure \
      -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
      -backend-config="key=${{ secrets.PROJECT_NAME }}/terraform.tfstate" \
      -backend-config="region=us-east-1"
  working-directory: infra/

- name: Terraform apply
  run: terraform apply -auto-approve -input=false
  working-directory: infra/
  env:
    AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    AWS_REGION:            us-east-1
    TF_VAR_cluster_name:   ${{ secrets.PROJECT_NAME }}
```

## Key outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API server endpoint |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `kms_key_arn` | KMS key ARN |
