# terraform-enterprise-modules

A production-grade **infrastructure module library** for AWS and Azure — available in both **Terraform HCL** and **Pulumi Go**.

Every module is a self-contained, versioned, composable unit. Solution packages compose modules into full environments (EKS, AKS) with a single reference.

> **Current version:** `v1.1.0` — [Releases](https://github.com/rafatusa/terraform-enterprise-modules/releases) · [Changelog](./CHANGELOG.md)

---

## What's in this library

### Terraform modules (`infra/modules/`)

| Cloud | Module | What it provisions |
|-------|--------|--------------------|
| AWS | `aws/vpc` | VPC, public + private subnets, IGW, NAT Gateways, Flow Logs |
| AWS | `aws/ec2` | EC2 instance, IMDSv2, encrypted EBS, optional EIP + IAM profile |
| AWS | `aws/eks` | EKS cluster, managed node groups, OIDC, KMS secrets encryption |
| AWS | `aws/rds` | RDS PostgreSQL, subnet group, security group, parameter group |
| AWS | `aws/s3` | S3 bucket, versioning, KMS encryption, lifecycle rules |
| AWS | `aws/security-group` | Configurable security group with ingress/egress rules |
| AWS | `aws/iam-role` | IAM role, trust policy, instance profile |
| AWS | `aws/kms` | KMS key, alias, automatic rotation |
| AWS | `aws/cloudwatch` | Log group, CPU/memory alarms, dashboard |
| Azure | `azure/resource-group` | Resource Group with optional delete lock |
| Azure | `azure/vnet` | VNet, subnets, service endpoints, DDoS protection optional |
| Azure | `azure/nsg` | NSG with configurable rules, subnet associations |
| Azure | `azure/managed-identity` | User-assigned Managed Identity, role assignments |
| Azure | `azure/log-analytics` | Log Analytics Workspace, Container Insights solution |
| Azure | `azure/aks` | AKS cluster, private API server, AAD RBAC, Workload Identity, CSI |

### Terraform solution packages (`infra/packages/`)

| Package | What it provisions |
|---------|--------------------|
| `aws-eks` | Full EKS environment — composes all 9 AWS modules in dependency order |
| `azure-aks` | Full AKS environment — composes all 6 Azure modules in dependency order |

### Pulumi Go components (`pulumi/modules/`)

Mirrors the Terraform module set exactly — same inputs, same outputs, same tagging convention. See [`pulumi/README.md`](./pulumi/README.md) for full Pulumi usage.

| Cloud | Package path | Component |
|-------|-------------|-----------|
| AWS | `pulumi/modules/aws/vpc` | `NewVpc` |
| AWS | `pulumi/modules/aws/ec2` | `NewInstance` |
| AWS | `pulumi/modules/aws/eks` | `NewCluster` |
| AWS | `pulumi/modules/aws/rds` | `NewDatabase` |
| AWS | `pulumi/modules/aws/s3` | `NewBucket` |
| AWS | `pulumi/modules/aws/security-group` | `NewSecurityGroup` |
| AWS | `pulumi/modules/aws/iam-role` | `NewRole` |
| AWS | `pulumi/modules/aws/kms` | `NewKey` |
| AWS | `pulumi/modules/aws/cloudwatch` | `NewMonitoring` |
| Azure | `pulumi/modules/azure/resource-group` | `NewResourceGroup` |
| Azure | `pulumi/modules/azure/vnet` | `NewVNet` |
| Azure | `pulumi/modules/azure/nsg` | `NewNSG` |
| Azure | `pulumi/modules/azure/managed-identity` | `NewManagedIdentity` |
| Azure | `pulumi/modules/azure/log-analytics` | `NewWorkspace` |
| Azure | `pulumi/modules/azure/aks` | `NewCluster` |

### Pulumi solution packages (`pulumi/packages/`)

| Package | Component |
|---------|-----------|
| `pulumi/packages/aws-eks` | `NewEnvironment` — full EKS environment |
| `pulumi/packages/azure-aks` | `NewEnvironment` — full AKS environment |

---

## Repository layout

```
terraform-enterprise-modules/
├── infra/                          # Terraform root (platform pipeline entry point)
│   ├── modules/
│   │   ├── aws/                    # 9 AWS Terraform modules
│   │   └── azure/                  # 6 Azure Terraform modules
│   └── packages/
│       ├── aws-eks/                # Full EKS environment package
│       └── azure-aks/              # Full AKS environment package
├── modules/                        # Module READMEs (docs-only, no .tf)
├── packages/                       # Package READMEs (docs-only, no .tf)
├── pulumi/
│   ├── go.mod                      # Single Go module for all Pulumi components
│   ├── modules/
│   │   ├── aws/                    # 9 AWS Pulumi Go components
│   │   └── azure/                  # 6 Azure Pulumi Go components
│   └── packages/
│       ├── aws-eks/                # Pulumi EKS environment package
│       └── azure-aks/              # Pulumi AKS environment package
├── .github/workflows/
│   ├── deploy.yml                  # Main CI: lint → validate → security → provision → verify
│   ├── destroy.yml                 # Teardown pipeline
│   ├── pulumi-ci.yml               # Pulumi Go: vet → build → staticcheck → gosec
│   ├── nightly-security-scan.yml   # tfsec + checkov full report
│   └── create-release.yml          # Tag + GitHub Release on push tag
└── CHANGELOG.md
```

---

## Consuming Terraform modules in your pipeline

### GitHub Actions — single module

```yaml
# .github/workflows/deploy.yml (your consumer repo)
jobs:
  provision:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

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
          TF_VAR_project_name:   ${{ secrets.PROJECT_NAME }}
          TF_VAR_aws_region:     us-east-1
```

Your `infra/main.tf` references the module by git tag:

```hcl
# infra/main.tf — consumer repo
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {}   # bucket/key/region injected by CI -backend-config flags
}

module "vpc" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.1.0"

  name        = var.project_name
  project     = var.project_name
  environment = "production"

  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway   = true
}

module "ec2" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/ec2?ref=v1.1.0"

  name               = var.project_name
  project            = var.project_name
  environment        = "production"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_group.security_group_id]
  ssh_public_key     = var.ssh_public_key
}
```

---

### GitHub Actions — full EKS environment (solution package)

```yaml
# .github/workflows/deploy.yml
jobs:
  provision:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
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

```hcl
# infra/main.tf — EKS consumer
module "eks_env" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/packages/aws-eks?ref=v1.1.0"

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
```

---

### GitHub Actions — full AKS environment (solution package)

```yaml
# .github/workflows/deploy.yml
jobs:
  provision:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"
      - name: Terraform init
        run: |
          terraform init -input=false -reconfigure \
            -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
            -backend-config="key=${{ secrets.PROJECT_NAME }}/terraform.tfstate" \
            -backend-config="region=westeurope"
        working-directory: infra/
      - name: Terraform apply
        run: terraform apply -auto-approve -input=false
        working-directory: infra/
        env:
          ARM_CLIENT_ID:       ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET:   ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID:       ${{ secrets.AZURE_TENANT_ID }}
          TF_VAR_cluster_name: ${{ secrets.PROJECT_NAME }}
          TF_VAR_location:     westeurope
```

```hcl
# infra/main.tf — AKS consumer
module "aks_env" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/packages/azure-aks?ref=v1.1.0"

  cluster_name        = var.cluster_name
  resource_group_name = "${var.cluster_name}-rg"
  location            = var.location
  environment         = "production"

  admin_group_object_ids = ["<your-aad-group-object-id>"]

  tags = {
    Project     = var.cluster_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

---

## Consuming Pulumi Go components in your pipeline

### GitHub Actions — single Pulumi component

```yaml
# .github/workflows/deploy.yml
jobs:
  provision:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"

      - uses: pulumi/actions@v5

      - name: Pulumi up
        run: pulumi up --yes --stack prod
        working-directory: infra/
        env:
          PULUMI_ACCESS_TOKEN:   ${{ secrets.PULUMI_ACCESS_TOKEN }}
          AWS_ACCESS_KEY_ID:     ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_REGION:            us-east-1
```

Your `infra/` Pulumi program imports the component by module path:

```go
// infra/go.mod
module my-infra

go 1.22

require (
    github.com/rafatusa/terraform-enterprise-modules/pulumi v1.1.0
    github.com/pulumi/pulumi/sdk/v3 v3.110.0
)
```

```go
// infra/main.go
package main

import (
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
    "github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/vpc"
    "github.com/rafatusa/terraform-enterprise-modules/pulumi/modules/aws/ec2"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        // Provision VPC
        v, err := vpc.NewVpc(ctx, "prod-vpc", &vpc.Args{
            Name:        pulumi.String("prod"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            AvailabilityZones: pulumi.StringArray{
                pulumi.String("us-east-1a"),
                pulumi.String("us-east-1b"),
            },
            PublicSubnetCidrs:  pulumi.StringArray{pulumi.String("10.0.1.0/24"), pulumi.String("10.0.2.0/24")},
            PrivateSubnetCidrs: pulumi.StringArray{pulumi.String("10.0.10.0/24"), pulumi.String("10.0.11.0/24")},
        })
        if err != nil {
            return err
        }

        // Provision EC2 in the first public subnet
        instance, err := ec2.NewInstance(ctx, "prod-ec2", &ec2.Args{
            Name:        pulumi.String("prod-ec2"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            SubnetID:    v.PublicSubnetIDs.Index(pulumi.Int(0)),
        })
        if err != nil {
            return err
        }

        ctx.Export("vpcId",     v.VpcID)
        ctx.Export("instanceId", instance.InstanceID)
        ctx.Export("publicIp",   instance.PublicIP)
        return nil
    })
}
```

---

### GitHub Actions — full EKS environment (Pulumi package)

```go
// infra/main.go
package main

import (
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
    awseks "github.com/rafatusa/terraform-enterprise-modules/pulumi/packages/aws-eks"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        env, err := awseks.NewEnvironment(ctx, "prod", &awseks.Args{
            ClusterName: pulumi.String("prod-eks"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            Region:      pulumi.String("us-east-1"),
        })
        if err != nil {
            return err
        }
        ctx.Export("clusterEndpoint", env.ClusterEndpoint)
        ctx.Export("vpcId",           env.VpcID)
        return nil
    })
}
```

---

### GitHub Actions — full AKS environment (Pulumi package)

```go
// infra/main.go
package main

import (
    "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
    azureaks "github.com/rafatusa/terraform-enterprise-modules/pulumi/packages/azure-aks"
)

func main() {
    pulumi.Run(func(ctx *pulumi.Context) error {
        env, err := azureaks.NewEnvironment(ctx, "prod", &azureaks.Args{
            ClusterName: pulumi.String("prod-aks"),
            Project:     pulumi.String("my-project"),
            Environment: pulumi.String("production"),
            Location:    pulumi.String("eastus"),
        })
        if err != nil {
            return err
        }
        ctx.Export("clusterName",        env.ClusterName)
        ctx.Export("resourceGroupName",  env.ResourceGroupName)
        return nil
    })
}
```

---

## Pinning versions

Always pin a release tag so your pipeline is deterministic.

**Terraform** — in `infra/main.tf`:
```hcl
source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.1.0"
```

**Pulumi Go** — in `go.mod`:
```go
require (
    github.com/rafatusa/terraform-enterprise-modules/pulumi v1.1.0
)
```

To upgrade:
```bash
# Terraform
# Update the ?ref= tag in main.tf, then:
terraform init -upgrade

# Pulumi
go get github.com/rafatusa/terraform-enterprise-modules/pulumi@v1.2.0
go mod tidy
```

---

## Module outputs quick reference

### AWS Terraform modules

| Module | Key outputs |
|--------|-------------|
| `aws/vpc` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_ids` |
| `aws/ec2` | `instance_id`, `public_ip`, `private_ip`, `security_group_id` |
| `aws/eks` | `cluster_name`, `cluster_endpoint`, `cluster_ca_certificate`, `oidc_provider_arn` |
| `aws/rds` | `endpoint`, `port`, `db_name`, `security_group_id` |
| `aws/s3` | `bucket_id`, `bucket_arn`, `bucket_name` |
| `aws/security-group` | `security_group_id`, `security_group_arn` |
| `aws/iam-role` | `role_arn`, `role_name`, `instance_profile_arn` |
| `aws/kms` | `key_id`, `key_arn`, `alias_arn` |
| `aws/cloudwatch` | `log_group_name`, `log_group_arn`, `cpu_alarm_arn` |

### Azure Terraform modules

| Module | Key outputs |
|--------|-------------|
| `azure/resource-group` | `name`, `id`, `location` |
| `azure/vnet` | `vnet_id`, `vnet_name`, `subnet_ids` |
| `azure/nsg` | `nsg_id`, `nsg_name` |
| `azure/managed-identity` | `id`, `principal_id`, `client_id`, `tenant_id` |
| `azure/log-analytics` | `workspace_id`, `workspace_name`, `customer_id` |
| `azure/aks` | `cluster_id`, `cluster_name`, `kube_config_raw`, `oidc_issuer_url` |

### Pulumi Go components

| Component | Key outputs |
|-----------|-------------|
| `aws/vpc` | `VpcID`, `PublicSubnetIDs`, `PrivateSubnetIDs` |
| `aws/ec2` | `InstanceID`, `PublicIP`, `PrivateIP`, `SecurityGroupID` |
| `aws/eks` | `ClusterName`, `ClusterEndpoint`, `ClusterARN`, `OIDCProviderURL` |
| `aws/rds` | `Endpoint`, `Port`, `DBName` |
| `aws/s3` | `BucketID`, `BucketARN`, `BucketName` |
| `aws/iam-role` | `RoleARN`, `RoleName`, `InstanceProfileARN` |
| `aws/kms` | `KeyID`, `KeyARN`, `AliasARN` |
| `aws/cloudwatch` | `LogGroupName`, `CPUAlarmARN`, `DashboardName` |
| `azure/resource-group` | `ResourceGroupName`, `ResourceGroupID`, `Location` |
| `azure/vnet` | `VNetName`, `VNetID`, `SubnetIDs` |
| `azure/nsg` | `NSGName`, `NSGID` |
| `azure/managed-identity` | `IdentityName`, `PrincipalID`, `ClientID` |
| `azure/log-analytics` | `WorkspaceName`, `WorkspaceID`, `CustomerID` |
| `azure/aks` | `ClusterName`, `ClusterID`, `KubeconfigRaw`, `OIDCIssuerURL` |

---

## Security defaults across all modules

| Default | Detail |
|---------|--------|
| Encryption at rest | KMS CMK on EBS, RDS, S3, EKS secrets; Azure Disk Encryption on AKS nodes |
| No public exposure | EC2 public IP off by default; EKS/AKS API private by default |
| IMDSv2 enforced | All EC2 instances (`http_tokens = required`) |
| Least-privilege IAM | Separate roles per workload; no `*` actions |
| Flow logs | VPC Flow Logs enabled by default |
| Tagging | Every resource tagged: `Project`, `Environment`, `ManagedBy`, `Module` |

---

## CI pipelines in this repo

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `deploy.yml` | push to `main` | lint → validate → tfsec → docs → provision → configure → verify |
| `destroy.yml` | manual dispatch | Teardown via `terraform destroy` |
| `pulumi-ci.yml` | push to `main` | `go vet` → `go build` → `staticcheck` → `gosec` → `nancy` |
| `nightly-security-scan.yml` | nightly cron | Full tfsec + checkov report saved as artifact |
| `create-release.yml` | push tag `v*` | Creates annotated GitHub Release from pushed tag |

---

## Related

- [Pulumi component library docs](./pulumi/README.md)
- [CHANGELOG](./CHANGELOG.md)
- [Module READMEs](./modules/) — individual Terraform module usage
- [Package READMEs](./packages/) — solution package usage
