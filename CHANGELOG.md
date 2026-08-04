# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-01-01

### Added
- **Pulumi Go Component Library** — parallel Pulumi implementation of all modules
- AWS Pulumi components: `vpc`, `ec2`, `eks`, `rds`, `s3`, `security-group`, `iam-role`, `kms`, `cloudwatch`
- Azure Pulumi components: `resource-group`, `vnet`, `nsg`, `managed-identity`, `log-analytics`, `aks`
- Pulumi solution packages: `aws-eks` (full EKS environment), `azure-aks` (full AKS environment)
- `pulumi-ci` CI pipeline: `go-lint → go-test → go-security` for all Pulumi modules
- `pulumi/go.mod` with pinned Pulumi SDK and provider versions

## [1.0.0] - 2025-01-01

### Added
- Initial release of the Enterprise Infrastructure Module Library
- **AWS Terraform modules (9):** `vpc`, `ec2`, `eks`, `rds`, `s3`, `security-group`, `iam-role`, `kms`, `cloudwatch`
- **Azure Terraform modules (6):** `resource-group`, `vnet`, `nsg`, `managed-identity`, `log-analytics`, `aks`
- **Solution packages:** `aws-eks` (full production EKS cluster), `azure-aks` (full production AKS cluster)
- CI/CD pipeline: `lint → validate → security (tfsec + checkov) → docs → provision → verify`
- Nightly security scan workflow (tfsec + checkov)
- Release workflow (creates git tag + GitHub Release)
- Per-module `README.md` auto-generation via `terraform-docs`
- All modules tagged: `Project`, `Environment`, `ManagedBy`, `Module`
- All module variables use pessimistic constraints (`~>`)

[Unreleased]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rafatusa/enterprise-infra-module/releases/tag/v1.0.0
