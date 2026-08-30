# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-08-30

### Changed — BREAKING

- **Repository layout is now symmetric across both IaC tools.** Every consumer
  `source` / import path changes. Pin to `v1.x` if you are not ready to migrate.

  ```
  infra/
    terraform/{modules,packages}/{aws,azure}/<name>/
    pulumi/{modules,packages}/{aws,azure}/<name>/
  ```

- Terraform modules moved from `infra/modules/<cloud>/<name>` to
  `infra/terraform/modules/<cloud>/<name>`. All 18 modules; `.tf` sources are
  byte-identical to v1.x — this is a path change only.
- Pulumi components moved from `pulumi/modules/<cloud>/<name>` to
  `infra/pulumi/modules/<cloud>/<name>`.
- Pulumi packages moved from `pulumi/packages/<name>` to
  `infra/pulumi/packages/<cloud>/<name>`, gaining a cloud segment for symmetry.
- Go module path is now
  `github.com/rafatusa/enterprise-infra-module/infra/pulumi`.

### Added

- **Terraform solution packages** — the Terraform counterparts of the existing
  Pulumi packages, which previously had no Terraform equivalent despite being
  listed in the v1.0.0 changelog:
  - `infra/terraform/packages/aws/aws-eks` — composes `vpc` + `kms` + `s3` +
    `eks` + `cloudwatch` into an opinionated EKS platform.
  - `infra/terraform/packages/azure/azure-aks` — composes `resource-group` +
    `vnet` + `nsg` + `managed-identity` + `log-analytics` + `aks`.

  Both are reusable compositions: no `backend`, no `provider`. The consuming
  root module owns state and provider configuration.

- `pulumi-ci` workflow is now declared in `.udap/pipeline.yaml` rather than
  existing only as a hand-maintained workflow file.

### Removed

- The composed root module (`infra/{main,variables,outputs,versions}.tf`) and
  its `backend "s3"` block. This repository is a module library; it deploys
  nothing and owns no state. CI now validates every module and package
  directory in isolation instead of a single root.
- Two stray `packages/*/README.md` files documenting packages that did not
  exist at those paths.

### Migration

```diff
 module "vpc" {
-  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/modules/aws/vpc?ref=v1.0.0"
+  source = "git::https://github.com/rafatusa/enterprise-infra-module.git//infra/terraform/modules/aws/vpc?ref=v2.0.0"
 }
```

```diff
-import "github.com/rafatusa/enterprise-infra-module/pulumi/modules/aws/vpc"
+import "github.com/rafatusa/enterprise-infra-module/infra/pulumi/modules/aws/vpc"
```

### Known issues

Carried over from v1.x and **not** addressed by this release, which is a
path-only restructure plus the two new packages:

- Module `README.md` files describe an earlier design in all 18 modules —
  inputs, outputs and defaults that do not match the code. Most consequential:
  `aws/rds` inverts the documented defaults of `deletion_protection` and
  `skip_final_snapshot`; `aws/iam` documents an entirely different resource;
  `azure/managed-identity` documents a `role_assignments` feature that does not
  exist. Treat the `.tf` sources as authoritative until the docs pass lands.
- `aws/rds` and `aws/elasticache` contain a non-ASCII character in an
  `aws_security_group` `description`, which the AWS API rejects on apply.
  CI does not catch this: it is valid HCL and no stage applies.

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

[Unreleased]: https://github.com/rafatusa/enterprise-infra-module/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rafatusa/enterprise-infra-module/releases/tag/v1.0.0
