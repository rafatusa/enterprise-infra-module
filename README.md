# enterprise-infra-module

A production-grade, multi-cloud Infrastructure-as-Code (IaC) module library providing reusable Terraform modules for AWS and Azure.

> **This repo is a module library — it does not deploy infrastructure itself.**
> Consumers pin to a release tag and source individual modules into their own vending projects.

---

## Module Catalogue

### AWS Modules (`infra/modules/aws/`)

| Module | Description | Key Resources |
|---|---|---|
| `vpc` | VPC with public/private subnets, IGW, NAT GW, route tables | `aws_vpc`, `aws_subnet`, `aws_nat_gateway` |
| `ec2` | EC2 instance with key pair and instance profile | `aws_instance`, `aws_key_pair` |
| `security-group` | Configurable security group with dynamic rules | `aws_security_group` |
| `rds` | Multi-AZ RDS instance with subnet group | `aws_db_instance`, `aws_db_subnet_group` |
| `eks` | EKS cluster with managed node group | `aws_eks_cluster`, `aws_eks_node_group` |
| `s3` | S3 bucket with versioning, encryption, public-access block | `aws_s3_bucket` |
| `alb` | Application Load Balancer with target group and listeners | `aws_lb`, `aws_lb_listener` |
| `elasticache` | ElastiCache Redis cluster with subnet group | `aws_elasticache_replication_group` |
| `iam` | IAM user/group/policy management | `aws_iam_user`, `aws_iam_policy` |
| `iam-role` | IAM role with instance profile and policy attachments | `aws_iam_role`, `aws_iam_instance_profile` |
| `kms` | KMS customer-managed key with rotation | `aws_kms_key`, `aws_kms_alias` |
| `cloudwatch` | CloudWatch log groups with configurable retention | `aws_cloudwatch_log_group` |

### Azure Modules (`infra/modules/azure/`)

| Module | Description | Key Resources |
|---|---|---|
| `resource-group` | Azure resource group | `azurerm_resource_group` |
| `vnet` | Virtual network with configurable subnets | `azurerm_virtual_network`, `azurerm_subnet` |
| `nsg` | Network security group with rule set and subnet association | `azurerm_network_security_group` |
| `aks` | AKS cluster with system + optional user node pools | `azurerm_kubernetes_cluster` |
| `managed-identity` | User-assigned managed identity with role assignments | `azurerm_user_assigned_identity` |
| `log-analytics` | Log Analytics workspace | `azurerm_log_analytics_workspace` |

---

## Module Versioning & Consumption

Modules are versioned via Git tags (`v1.0.0`, `v1.1.0`, …). Pin to a tag in your consuming project so you always get a stable, auditable snapshot.

### Source pattern

```hcl
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/vpc?ref=v1.0.0"

  project_name         = "my-app"
  environment          = "prod"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}

module "ec2" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/ec2?ref=v1.0.0"

  project_name       = "my-app"
  environment        = "prod"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_group.security_group_id]
  ssh_public_key     = var.ssh_public_key
}
```

The double-slash (`//`) separates the repo from the module subdirectory path — this is Terraform's required syntax for Git sources.

### Available versions

See [Releases](https://github.com/rafatusa/enterprise-infra-module/releases) for the full changelog.

---

## Releasing a New Version

1. **Bump the version** — edit the `VERSION` file at the repo root:
   ```
   1.1.0
   ```
2. **Commit and push** to `main`:
   ```bash
   git add VERSION
   git commit -m "chore: bump version to v1.1.0"
   git push
   ```
3. **Trigger the release workflow** — in GitHub go to:
   **Actions → Release → Run workflow → Run workflow**

   The workflow will:
   - Verify the tag `v1.1.0` does not already exist
   - Create an annotated Git tag `v1.1.0`
   - Publish a GitHub Release with auto-generated notes

4. **Consumers update their `ref`**:
   ```hcl
   source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/vpc?ref=v1.1.0"
   ```
   then run `terraform init -upgrade` to pull the new module version.

---

## Local Example Consumer

`infra/` is a reference implementation that wires all AWS modules together. It is **not deployed by this repo's pipeline** — it exists to validate module references and serve as a copy-paste starting point.

```bash
cd infra/
terraform init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="key=enterprise-infra-module/terraform.tfstate" \
  -backend-config="region=us-east-1"

terraform plan \
  -var="project_name=demo" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
```

---

## CI/CD Pipeline

Every push to `main` runs the full validation suite. **No cloud resources are provisioned by this pipeline.**

| Stage | Kind | What it does |
|---|---|---|
| `lint` | lint | `terraform fmt` check + TFLint (AWS plugin) on all modules |
| `security` | security | tfsec + checkov against all modules |
| `validate` | provision | `terraform init -backend=false` + `terraform validate` on the example consumer |
| `docs-check` | configure | Asserts every module has `main.tf`, `variables.tf`, `outputs.tf`, `README.md` |
| `verify` | verify | Prints a pass summary |
| `nightly-scan` | scheduled | Deep tfsec + checkov sweep + terraform-docs regeneration (02:00 UTC) |
| `release` | manual dispatch | Creates annotated git tag + GitHub Release from `VERSION` file |

---

## Security

- All resources are tagged with `Project`, `Environment`, and `ManagedBy=terraform`.
- S3 buckets have public-access block enabled and SSE-KMS encryption.
- RDS instances are deployed in private subnets with deletion protection enabled.
- **SSH access:** the example `infra/` consumer opens port 22 to `0.0.0.0/0` by default. Set `allowed_ssh_cidrs` to restrict this in production, or use AWS SSM Session Manager and remove port 22 entirely.
- Security scans run on every push (tfsec, checkov) and nightly.

---

## Contributing

1. Add new modules under `infra/modules/<cloud>/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
2. Run `terraform-docs markdown table --output-file README.md infra/modules/<cloud>/<name>/` to generate the module README.
3. All modules must pass `tflint` and `checkov` — run the CI pipeline to verify.
4. To ship: bump `VERSION`, merge to `main`, trigger the **Release** workflow.
