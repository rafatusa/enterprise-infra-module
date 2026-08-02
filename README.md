# terraform-enterprise-modules

[![CI](https://github.com/your-org/terraform-enterprise-modules/actions/workflows/deploy.yml/badge.svg)](https://github.com/your-org/terraform-enterprise-modules/actions/workflows/deploy.yml)
[![Nightly Security Scan](https://github.com/your-org/terraform-enterprise-modules/actions/workflows/nightly-security-scan.yml/badge.svg)](https://github.com/your-org/terraform-enterprise-modules/actions/workflows/nightly-security-scan.yml)

The organization's **centralized Terraform module library** — reusable, production-grade infrastructure building blocks for **AWS** and **Azure**, composed into higher-level solution packages.

## Philosophy

This repository is a **package manager for infrastructure**. Two layers:

```
packages/          ← One reference → complete environment
  aws-eks/         ← VPC + SGs + IAM + KMS + EKS + CloudWatch
  azure-aks/       ← RG + VNet + NSG + Log Analytics + Identity + AKS

modules/           ← Single-responsibility building blocks
  aws/             ← vpc, ec2, eks, rds, s3, security-group, iam-role, kms, cloudwatch
  azure/           ← resource-group, vnet, nsg, log-analytics, managed-identity, aks
```

**Use a package** when you need a complete environment.  
**Use a module** when you need a specific resource with enterprise defaults.

---

## Quick Start

### AWS EKS Cluster

```hcl
module "eks_env" {
  source = "github.com/your-org/terraform-enterprise-modules//packages/aws-eks?ref=v1.0.0"

  cluster_name    = "platform-eks"
  cluster_version = "1.29"

  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  node_groups = {
    general = {
      instance_types = ["m5.xlarge"]
      desired_size   = 3
      min_size       = 1
      max_size       = 20
    }
  }

  tags = { Environment = "production", Project = "platform" }
}
```

### Azure AKS Cluster

```hcl
module "aks_env" {
  source = "github.com/your-org/terraform-enterprise-modules//packages/azure-aks?ref=v1.0.0"

  cluster_name        = "platform-aks"
  resource_group_name = "platform-aks-rg"
  location            = "eastus"

  admin_group_object_ids = ["<aad-group-object-id>"]

  user_node_pools = [{
    name            = "apps"
    vm_size         = "Standard_D8s_v5"
    node_count      = 3
    min_count       = 2
    max_count       = 20
    os_disk_size_gb = 128
    max_pods        = 110
  }]

  tags = { Environment = "production", Project = "platform" }
}
```

---

## Module Catalog

### AWS Modules (`modules/aws/`)

| Module | Description |
|--------|-------------|
| [vpc](modules/aws/vpc/README.md) | VPC, subnets, IGW, NAT Gateway, route tables |
| [ec2](modules/aws/ec2/README.md) | EC2 instance with SSM, EBS encryption, key pair |
| [eks](modules/aws/eks/README.md) | EKS cluster with managed node groups and IRSA |
| [rds](modules/aws/rds/README.md) | RDS (Postgres/MySQL) in a Multi-AZ subnet group |
| [s3](modules/aws/s3/README.md) | S3 bucket with versioning, encryption, lifecycle |
| [security-group](modules/aws/security-group/README.md) | Security group with rule maps |
| [iam-role](modules/aws/iam-role/README.md) | IAM role with assume-role policy + managed policies |
| [kms](modules/aws/kms/README.md) | KMS key with alias, rotation, and key policy |
| [cloudwatch](modules/aws/cloudwatch/README.md) | CloudWatch log group with KMS encryption |

### Azure Modules (`modules/azure/`)

| Module | Description |
|--------|-------------|
| [resource-group](modules/azure/resource-group/README.md) | Azure Resource Group |
| [vnet](modules/azure/vnet/README.md) | VNet with configurable subnets |
| [nsg](modules/azure/nsg/README.md) | Network Security Group with subnet associations |
| [log-analytics](modules/azure/log-analytics/README.md) | Log Analytics Workspace + solutions |
| [managed-identity](modules/azure/managed-identity/README.md) | User Assigned Managed Identity + RBAC |
| [aks](modules/azure/aks/README.md) | AKS cluster: private, AAD, Workload Identity |

### Solution Packages (`packages/`)

| Package | Cloud | What it provisions |
|---------|-------|--------------------|
| [aws-eks](packages/aws-eks/README.md) | AWS | VPC · SGs · KMS · IAM × 2 · EKS · CloudWatch |
| [azure-aks](packages/azure-aks/README.md) | Azure | RG · VNet · NSG · Log Analytics · Identity · AKS |

---

## Enterprise Standards

Every module and package enforces:

| Standard | Implementation |
|----------|---------------|
| **Encryption at rest** | KMS (AWS), platform-managed + CMK option (Azure) |
| **Encryption in transit** | TLS enforced on all endpoints |
| **Least-privilege IAM** | Scoped policies, no `*` actions in custom policies |
| **Tagging** | `ManagedBy`, `Module` auto-applied; consumers pass `Project`, `Environment` |
| **Input validation** | `validation {}` blocks on every critical variable |
| **Sensitive outputs** | `sensitive = true` on keys, kubeconfigs, connection strings |
| **Version pinning** | Pessimistic constraints (`~>`) on all providers |
| **Documentation** | README per module: usage, inputs table, outputs table |

---

## CI/CD Gates

Every pull request runs:

| Stage | Tool | What it checks |
|-------|------|----------------|
| **Lint** | TFLint | Deprecated syntax, best-practice violations |
| **Validate** | `terraform validate` | HCL correctness for all modules + packages |
| **Security** | tfsec + checkov | SAST rules, misconfiguration, secrets |
| **Docs** | terraform-docs | README freshness |

Nightly: full tfsec + checkov scans saved as GitHub Actions artifacts.

---

## Versioning & Consuming Modules

Modules are versioned by **git tag** (`vMAJOR.MINOR.PATCH`).

Reference by tag — never by branch:

```hcl
source = "github.com/your-org/terraform-enterprise-modules//modules/aws/vpc?ref=v1.0.0"
```

See [CHANGELOG.md](CHANGELOG.md) for the release history.

---

## Repository Structure

```
terraform-enterprise-modules/
├── modules/
│   ├── aws/
│   │   ├── vpc/
│   │   ├── ec2/
│   │   ├── eks/
│   │   ├── rds/
│   │   ├── s3/
│   │   ├── security-group/
│   │   ├── iam-role/
│   │   ├── kms/
│   │   └── cloudwatch/
│   └── azure/
│       ├── resource-group/
│       ├── vnet/
│       ├── nsg/
│       ├── log-analytics/
│       ├── managed-identity/
│       └── aks/
├── packages/
│   ├── aws-eks/
│   └── azure-aks/
├── infra/                  ← Platform pipeline sentinel (no-op null_resource)
├── .tflint.hcl
├── CHANGELOG.md
└── README.md
```

---

## Contributing

1. One module = one resource type. No business logic in modules.
2. Every module needs: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`.
3. All variables that can be dangerous must have a `validation {}` block.
4. Sensitive outputs must set `sensitive = true`.
5. Tag every resource with at minimum `ManagedBy = "terraform"` and `Module = "<path>"`.
6. Run `terraform-docs` to regenerate the README table before opening a PR.
7. Open a PR → CI must be green → request a review.
