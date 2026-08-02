# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial module library with AWS and Azure modules
- Solution packages: `aws-eks`, `azure-aks`
- CI/CD pipeline: lint, validate, tfsec, checkov, terraform-docs
- Nightly security scan workflow

---

## [1.0.0] - TBD

### Added

#### AWS Modules
- `modules/aws/vpc` — VPC with public/private subnets, IGW, NAT Gateway, route tables
- `modules/aws/ec2` — EC2 with EBS encryption, SSM, key pair injection
- `modules/aws/eks` — EKS cluster with managed node groups, IRSA, envelope encryption
- `modules/aws/rds` — RDS (Postgres/MySQL) with Multi-AZ, encryption, subnet group
- `modules/aws/s3` — S3 with versioning, AES256/KMS encryption, lifecycle rules
- `modules/aws/security-group` — Security group with ingress/egress rule maps
- `modules/aws/iam-role` — IAM role with assume-role and managed policy attachment
- `modules/aws/kms` — KMS key with alias, automatic rotation, key policy
- `modules/aws/cloudwatch` — CloudWatch log group with retention and KMS encryption

#### Azure Modules
- `modules/azure/resource-group` — Resource Group with lifecycle protection
- `modules/azure/vnet` — VNet with configurable subnets and service endpoints
- `modules/azure/nsg` — NSG with security rules and subnet associations
- `modules/azure/log-analytics` — Log Analytics Workspace with Container/VM Insights
- `modules/azure/managed-identity` — User Assigned Managed Identity with RBAC assignments
- `modules/azure/aks` — AKS: private cluster, AAD RBAC, Workload Identity, CSI driver, diagnostics

#### Solution Packages
- `packages/aws-eks` — Complete EKS environment (VPC + IAM + KMS + EKS + CloudWatch)
- `packages/azure-aks` — Complete AKS environment (RG + VNet + NSG + Logs + Identity + AKS)

---

[Unreleased]: https://github.com/your-org/terraform-enterprise-modules/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/terraform-enterprise-modules/releases/tag/v1.0.0
