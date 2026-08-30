# enterprise-infra-module

A production-grade, multi-cloud infrastructure module library for AWS and Azure,
published for **both Terraform and Pulumi**.

> **This repo is a module library — it never provisions infrastructure itself.**
> Other repos (your application stacks, platform vending pipelines) pin to a release tag
> and source individual modules on demand. The CI in this repo only validates and releases.

> **⚠️ v2.0.0 is a breaking change.** Every module path moved. See
> [CHANGELOG.md](CHANGELOG.md) for the migration diff. Pin to `v1.x` if you are
> not ready to migrate.

> **⚠️ Known documentation defect.** The per-module `README.md` files and several
> examples below describe an earlier design: some document inputs and outputs that
> do not exist in the code. **The `.tf` and `.go` sources are authoritative.** A
> documentation-accuracy pass is tracked separately; see the *Known issues*
> section of [CHANGELOG.md](CHANGELOG.md).

---

## Repository Layout

```
infra/
  terraform/
    modules/
      aws/     vpc ec2 security-group rds eks s3 alb
               elasticache iam iam-role kms cloudwatch
      azure/   resource-group vnet nsg aks
               managed-identity log-analytics
    packages/
      aws/aws-eks/          composed EKS platform
      azure/azure-aks/      composed AKS platform
  pulumi/
    modules/
      aws/     vpc ec2 s3 kms security-group iam-role rds cloudwatch eks
      azure/   resource-group vnet nsg managed-identity log-analytics aks
    packages/
      aws/aws-eks/
      azure/azure-aks/
```

The two trees are mirror images: the same component exists at the same coordinates
under `terraform/` and `pulumi/`.

---

## Table of Contents

- [How Consuming Repos Use This Library](#how-consuming-repos-use-this-library)
- [Solution Packages](#solution-packages)
- [Pulumi Library](#pulumi-library)
- [On-Demand Deployment Pattern (GitHub Actions)](#on-demand-deployment-pattern-github-actions)
- [Module Reference — AWS](#module-reference--aws)
- [Module Reference — Azure](#module-reference--azure)
- [Composing Modules Together](#composing-modules-together)
- [Version Pinning Strategy](#version-pinning-strategy)
- [Releasing a New Version](#releasing-a-new-version)
- [CI Pipeline (This Repo)](#ci-pipeline-this-repo)
- [Contributing](#contributing)

---

## How Consuming Repos Use This Library

### 1. Create a `main.tf` in your consuming repo

Reference any module using Terraform's Git source with a version `ref`:

```hcl
# main.tf — in YOUR application / platform repo

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Your own state backend
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=v2.0.0"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway   = true
}

module "ec2" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/ec2?ref=v2.0.0"

  project_name   = var.project_name
  environment    = var.environment
  subnet_id      = module.vpc.public_subnet_ids[0]
  ssh_public_key = var.ssh_public_key
}
```

### 2. Run `terraform init` — Terraform fetches the module at that exact tag

```bash
terraform init \
  -backend-config="bucket=my-state-bucket" \
  -backend-config="key=my-app/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

Terraform clones this repo at `v2.0.0`, caches it in `.terraform/`, and never talks to it again
until you run `terraform init -upgrade` with a newer `ref`.

### 3. To upgrade to a newer release

```hcl
# Bump the ref in every module source
source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=v2.1.0"
```

```bash
terraform init -upgrade   # re-fetches from the new tag
terraform plan
terraform apply
```

---

## Solution Packages

Packages compose several modules into one opinionated stack. They are reusable
compositions — they declare **no backend and no provider**; your root module owns both.

### `aws-eks`

Composes `vpc` + `kms` + `s3` + `eks` + `cloudwatch`.

```hcl
module "platform" {
  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/terraform/packages/aws/aws-eks?ref=v2.0.0"

  project_name = "acme"
  environment  = "prod"

  azs                  = ["us-east-1a", "us-east-1b"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
  instance_types       = ["t3.large"]
  desired_size         = 3
}
```

See [`infra/terraform/packages/aws/aws-eks/README.md`](infra/terraform/packages/aws/aws-eks/README.md)
for the full input and output reference.

### `azure-aks`

Composes `resource-group` + `vnet` + `nsg` + `managed-identity` + `log-analytics` + `aks`.

```hcl
module "platform" {
  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/terraform/packages/azure/azure-aks?ref=v2.0.0"

  project_name = "acme"
  environment  = "prod"
  location     = "eastus"

  system_node_count   = 3
  system_node_vm_size = "Standard_D4s_v3"
}
```

See [`infra/terraform/packages/azure/azure-aks/README.md`](infra/terraform/packages/azure/azure-aks/README.md)
for the full input and output reference.

---

## Pulumi Library

The same components are available as Pulumi Go components under `infra/pulumi/`.

```bash
go get github.com/rafatusa/enterprise-infra-module/infra/pulumi@v2.0.0
```

```go
import (
    "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/aws/vpc"
    awseks "github.com/rafatusa/enterprise-infra-module/infra/pulumi/packages/aws/aws-eks"
)
```

See [`infra/pulumi/README.md`](infra/pulumi/README.md) for component reference and usage.

---

## On-Demand Deployment Pattern (GitHub Actions)

The recommended pattern for consuming repos: a `workflow_dispatch` workflow that takes
the resource type and environment as inputs, then runs `terraform apply` against the
correct module. Your state backend and cloud credentials live in **your** repo's secrets —
this module library repo does not need any of them.

### Minimal example — deploy any AWS module on demand

```yaml
# .github/workflows/deploy-infra.yml  (in YOUR consuming repo)
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      module:
        description: "Module to deploy (vpc | ec2 | rds | eks | s3 | alb | elasticache | kms)"
        required: true
        type: choice
        options: [vpc, ec2, rds, eks, s3, alb, elasticache, kms]
      environment:
        description: "Target environment"
        required: true
        type: choice
        options: [dev, staging, prod]
      module_version:
        description: "Module library version tag"
        required: true
        default: "v2.0.0"

jobs:
  deploy:
    name: Deploy ${{ inputs.module }} to ${{ inputs.environment }}
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}   # maps to a GitHub Environment with its own secrets

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"

      - name: Terraform Init
        working-directory: infra/${{ inputs.module }}
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION:            us-east-1
        run: |
          terraform init -input=false -reconfigure \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=${{ inputs.environment }}/${{ inputs.module }}/terraform.tfstate" \
            -backend-config="region=us-east-1"

      - name: Terraform Plan
        working-directory: infra/${{ inputs.module }}
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION:            us-east-1
          TF_VAR_module_version: ${{ inputs.module_version }}
          TF_VAR_environment:    ${{ inputs.environment }}
        run: terraform plan -input=false -out=tfplan

      - name: Terraform Apply
        working-directory: infra/${{ inputs.module }}
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION:            us-east-1
          TF_VAR_module_version: ${{ inputs.module_version }}
          TF_VAR_environment:    ${{ inputs.environment }}
        run: terraform apply -input=false tfplan
```

Each `infra/<module>/` directory in **your** consuming repo holds a thin `main.tf` that
sources the module from this library at the chosen version ref:

```hcl
# infra/vpc/main.tf  (in YOUR consuming repo)
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=${var.module_version}"

  project_name = var.project_name
  environment  = var.environment
}

variable "module_version" {}
variable "project_name"   { default = "my-platform" }
variable "environment"    {}
```

### Advanced pattern — environment matrix with approval gates

```yaml
# .github/workflows/deploy-infra.yml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      module:
        description: "Module name"
        required: true
      module_version:
        description: "Release tag (e.g. v2.0.0)"
        required: true
        default: "v2.0.0"

jobs:
  plan:
    name: Plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Plan
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          cd infra/${{ inputs.module }}
          terraform init -input=false -reconfigure \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=prod/${{ inputs.module }}/terraform.tfstate" \
            -backend-config="region=us-east-1"
          terraform plan -input=false -out=tfplan
      - uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: infra/${{ inputs.module }}/tfplan

  approve:
    name: Approval Gate
    needs: plan
    runs-on: ubuntu-latest
    environment: production   # <- requires a human to approve in GitHub Environments
    steps:
      - run: echo "Plan approved — proceeding to apply"

  apply:
    name: Apply
    needs: approve
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: tfplan
          path: infra/${{ inputs.module }}/
      - uses: hashicorp/setup-terraform@v3
      - name: Apply
        env:
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          cd infra/${{ inputs.module }}
          terraform init -input=false -reconfigure \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=prod/${{ inputs.module }}/terraform.tfstate" \
            -backend-config="region=us-east-1"
          terraform apply -input=false tfplan
```

> **Secrets your consuming repo needs** (set these in its GitHub repo settings):
> | Secret | Value |
> |---|---|
> | `AWS_ACCESS_KEY_ID` | AWS access key with deploy permissions |
> | `AWS_SECRET_ACCESS_KEY` | Corresponding secret key |
> | `TF_STATE_BUCKET` | S3 bucket name for your Terraform state |

---

## Module Reference — AWS

All modules accept `project_name` (required) and `environment` (default: `"dev"`).
Every resource is tagged with `Project`, `Environment`, and `ManagedBy=terraform`.

> The examples below are inherited from v1.x and are **known to contain arguments
> that do not exist** in some modules. Check the module's `variables.tf` before use.

### `vpc` — VPC with public/private subnets

```hcl
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=v2.0.0"

  project_name         = "my-app"
  environment          = "prod"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway   = true            # set false to skip NAT GW (saves ~$32/mo)
  tags                 = { Team = "platform" }
}
```

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_id` | NAT Gateway ID (null if disabled) |
| `internet_gateway_id` | Internet Gateway ID |

---

### `ec2` — EC2 instance

```hcl
module "ec2" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/ec2?ref=v2.0.0"

  project_name         = "my-app"
  environment          = "prod"
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.security_group.security_group_id]
  ssh_public_key       = var.ssh_public_key     # sensitive — pass via TF_VAR or secret
  instance_type        = "t3.small"
  root_volume_size     = 40
  iam_instance_profile = module.iam_role.instance_profile_name   # optional
}
```

| Output | Description |
|---|---|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP (empty if private subnet) |
| `private_ip` | Private IP |
| `key_pair_name` | Name of the created key pair |

---

### `security-group` — Security group with dynamic rules

```hcl
module "sg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/security-group?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],  description = "HTTP" },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"],  description = "HTTPS" },
    { from_port = 22,  to_port = 22,  protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "SSH internal" }
  ]
}
```

| Output | Description |
|---|---|
| `security_group_id` | Security group ID |

---

### `rds` — RDS (Postgres / MySQL / MariaDB)

> **Warning:** the v1.x example below documented `deletion_protection` and
> `skip_final_snapshot` defaults that are the **inverse** of the module's actual
> defaults (`false` and `true` respectively). Set them explicitly for production.

```hcl
module "rds" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/rds?ref=v2.0.0"

  project_name               = "my-app"
  environment                = "prod"
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.sg.security_group_id]

  engine                  = "postgres"
  engine_version          = "15.4"
  family                  = "postgres15"
  instance_class          = "db.t3.small"
  db_name                 = "myapp"
  username                = "dbadmin"
  password                = var.db_password    # sensitive — use TF_VAR_db_password in CI
  multi_az                = true               # production HA
  deletion_protection     = true               # module default is false — set explicitly
  skip_final_snapshot     = false              # module default is true — set explicitly
  backup_retention_period = 7
}
```

| Output | Description |
|---|---|
| `db_instance_id` | RDS instance identifier |
| `db_endpoint` | Connection endpoint (host:port) |
| `db_name` | Database name |
| `db_port` | Port number |

---

### `eks` — EKS cluster with managed node group

```hcl
module "eks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/eks?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  subnet_ids   = module.vpc.private_subnet_ids   # needs at least 2 AZs

  kubernetes_version = "1.29"
  instance_types     = ["t3.medium"]
  capacity_type      = "ON_DEMAND"    # or SPOT for cost savings
  desired_size       = 2
  min_size           = 1
  max_size           = 5
}
```

| Output | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | API server endpoint |
| `cluster_ca_certificate` | Base64-encoded CA cert |
| `cluster_role_arn` | Cluster IAM role ARN |
| `node_group_role_arn` | Node IAM role ARN |

---

### `alb` — Application Load Balancer

```hcl
module "alb" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/alb?ref=v2.0.0"

  project_name       = "my-app"
  environment        = "prod"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.sg.security_group_id]
  target_port        = 8080
  health_check_path  = "/health"
}
```

| Output | Description |
|---|---|
| `alb_arn` | ALB ARN |
| `alb_dns_name` | DNS name to point your domain at |
| `target_group_arn` | Target group ARN (attach EC2/ECS targets here) |

---

### `s3` — S3 bucket (versioned, encrypted, private)

```hcl
module "s3" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/s3?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  kms_key_arn  = module.kms.key_arn    # optional — uses SSE-S3 if omitted
}
```

---

### `kms` — Customer-managed KMS key

```hcl
module "kms" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/kms?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  key_name     = "app"
  description  = "Encryption key for my-app prod"
}
```

| Output | Description |
|---|---|
| `key_id` | KMS key ID |
| `key_arn` | KMS key ARN (pass to s3, rds, etc.) |
| `alias_name` | KMS alias name |
| `alias_arn` | KMS alias ARN |

---

### `elasticache` — ElastiCache Redis

```hcl
module "redis" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/elasticache?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  subnet_ids   = module.vpc.private_subnet_ids
  vpc_id       = module.vpc.vpc_id
  node_type    = "cache.t3.micro"
}
```

---

### `iam-role` — IAM role with instance profile

```hcl
module "app_role" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam-role?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}
```

| Output | Description |
|---|---|
| `role_arn` | IAM role ARN |
| `role_name` | IAM role name |
| `instance_profile_name` | Instance profile name (pass to ec2 module) |

---

### `cloudwatch` — CloudWatch log group and metric alarms

```hcl
module "logs" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/cloudwatch?ref=v2.0.0"

  project_name      = "my-app"
  environment       = "prod"
  log_group_name    = "app"     # suffix — prefixed with /aws/<project>/<env>/
  retention_in_days = 30
}
```

---

## Module Reference — Azure

All Azure modules require `project_name`, `environment`, and `location`.

### `resource-group`

```hcl
module "rg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/resource-group?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  location     = "eastus"
}
```

| Output | Description |
|---|---|
| `resource_group_name` | Resource group name |
| `resource_group_id` | Resource group ID |
| `location` | Resource group location |

---

### `vnet` — Virtual Network

```hcl
module "vnet" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/vnet?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  location            = module.rg.location
  resource_group_name = module.rg.resource_group_name
  address_space       = ["10.0.0.0/16"]
  subnets = [
    { name = "public",  address_prefixes = ["10.0.1.0/24"] },
    { name = "private", address_prefixes = ["10.0.10.0/24"] }
  ]
}
```

| Output | Description |
|---|---|
| `vnet_id` | Virtual network ID |
| `vnet_name` | Virtual network name |
| `subnet_ids` | Map of subnet name to subnet ID |

---

### `nsg` — Network Security Group

```hcl
module "nsg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/nsg?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  location            = module.rg.location
  resource_group_name = module.rg.resource_group_name
  subnet_ids          = [module.vnet.subnet_ids["public"]]
}
```

> Omitting `security_rules` applies the module default: allow HTTPS inbound,
> deny all other inbound.

---

### `aks` — Azure Kubernetes Service

```hcl
module "aks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/aks?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  location            = module.rg.location
  resource_group_name = module.rg.resource_group_name
  subnet_id           = module.vnet.subnet_ids["private"]
  system_node_vm_size = "Standard_D2s_v3"
  system_node_count   = 2
}
```

---

### `managed-identity` — User-assigned Managed Identity

```hcl
module "identity" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/managed-identity?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  location            = module.rg.location
  resource_group_name = module.rg.resource_group_name
}
```

---

### `log-analytics` — Log Analytics Workspace

```hcl
module "logs" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/log-analytics?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  location            = module.rg.location
  resource_group_name = module.rg.resource_group_name
  retention_in_days   = 30
}
```

---

## Composing Modules Together

For the common cases, prefer a [solution package](#solution-packages) over wiring
modules by hand.

### Full AWS stack: VPC + EC2 + RDS + ALB

```hcl
module "vpc"  { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=v2.0.0"  ... }
module "sg"   { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/security-group?ref=v2.0.0" ... }
module "role" { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/iam-role?ref=v2.0.0" ... }
module "kms"  { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/kms?ref=v2.0.0"  ... }

module "ec2" {
  source               = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/ec2?ref=v2.0.0"
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.sg.security_group_id]
  iam_instance_profile = module.role.instance_profile_name
}

module "rds" {
  source                     = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/rds?ref=v2.0.0"
  subnet_ids                 = module.vpc.private_subnet_ids
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = [module.sg.security_group_id]
}

module "alb" {
  source             = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/alb?ref=v2.0.0"
  subnet_ids         = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.sg.security_group_id]
}
```

### Full Azure stack: Resource Group + VNet + NSG + AKS

```hcl
module "rg"   { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/resource-group?ref=v2.0.0" ... }
module "vnet" { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/vnet?ref=v2.0.0"  resource_group_name = module.rg.resource_group_name ... }
module "nsg"  { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/nsg?ref=v2.0.0"   resource_group_name = module.rg.resource_group_name ... }
module "aks"  { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/aks?ref=v2.0.0"   resource_group_name = module.rg.resource_group_name ... }
module "logs" { source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/azure/log-analytics?ref=v2.0.0" resource_group_name = module.rg.resource_group_name ... }
```

---

## Version Pinning Strategy

| Scenario | Recommendation |
|---|---|
| Production workloads | Always pin to an exact tag: `?ref=v2.0.0` |
| Development / experimentation | Use a short SHA for a specific commit: `?ref=abc1234` |
| Never do this | `?ref=main` — main can change at any time |

**Watch for new releases:** go to this repo → Watch → Custom → tick **Releases** — GitHub
notifies you when a new version is published.

**To upgrade a consuming repo:**
1. Check the [Releases page](https://github.com/rafatusa/enterprise-infra-module/releases) for the changelog.
2. Bump every `?ref=` to the new tag.
3. Run `terraform init -upgrade` then `terraform plan` to review the diff.
4. Apply.

Upgrading from `v1.x` to `v2.0.0` also requires changing every module **path** —
see [CHANGELOG.md](CHANGELOG.md).

---

## Releasing a New Version

1. **Bump** the `VERSION` file at the repo root (e.g. `2.1.0`).
2. **Commit and push** to `main`:
   ```bash
   git add VERSION
   git commit -m "chore: bump version to v2.1.0"
   git push
   ```
3. **Trigger the release workflow** in GitHub:
   **Actions → Release → Run workflow → Run workflow**

   The workflow reads `VERSION`, verifies the tag is unique, creates an annotated Git tag,
   and publishes a GitHub Release with auto-generated notes.

4. Consumers update their `?ref=` and run `terraform init -upgrade`.

---

## CI Pipeline (This Repo)

Every push runs the validation suite. **No cloud resources are ever provisioned.**

| Stage | What it does |
|---|---|
| `lint` | `terraform fmt -check` + TFLint (AWS ruleset) across every module and package |
| `security` | tfsec + checkov static analysis over `infra/terraform` |
| `validate` | `terraform init -backend=false` + `terraform validate` on every module and package directory |
| `docs-check` | Asserts every module/package has `main.tf`, `variables.tf`, `outputs.tf`, `README.md`, and every Pulumi component has Go sources |
| `verify` | Prints a summary confirming all gates passed |
| `pulumi-ci` | Separate workflow — `gofmt` + `go vet` + staticcheck, `go build`, gosec |
| `nightly-scan` | Deep tfsec + checkov sweep + terraform-docs regeneration |
| `release` | Manual dispatch — creates annotated git tag + GitHub Release from `VERSION` |

Because this repo owns no state and deploys nothing, modules and packages declare
**no backend block**. State is always the consumer's responsibility.

---

## Contributing

1. Add new Terraform modules under `infra/terraform/modules/<cloud>/<name>/` with
   `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
2. Add the mirroring Pulumi component under `infra/pulumi/modules/<cloud>/<name>/`.
3. Tag every resource with `Project`, `Environment`, and `ManagedBy = "terraform"`.
4. Keep module `README.md` files accurate against the code — every input, output and
   default in the table must exist. See the *Known issues* in [CHANGELOG.md](CHANGELOG.md).
5. Ensure the module passes `tflint`, `tfsec`, and `checkov` — push to a branch and the
   CI suite runs automatically.
6. Open a PR. After merge to `main`, bump `VERSION` and trigger the **Release** workflow.
