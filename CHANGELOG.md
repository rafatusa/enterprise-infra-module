# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-08-30

Correctness pass over the library shipped in 2.0.0. Where 2.0.0 moved files,
this release fixes what those files actually do and say. Two of the fixes are
apply-blocking bugs that no CI stage in this repo can detect.

### Fixed — apply-blocking

- **`aws/rds` and `aws/elasticache` no longer fail `terraform apply`.** Both
  hardcoded an em-dash (U+2014) in their `aws_security_group` `description`.
  The AWS API rejects non-ASCII in that field, so any consumer of either module
  hit an immediate `InvalidParameterValue` on apply. Replaced with an ASCII
  hyphen.

  This was invisible to CI by construction: an em-dash is valid HCL, so
  `fmt`, `validate` and `tflint` all pass, and no stage in this repository runs
  `apply`. It was equally invisible in v1.x because the composed root module
  never instantiated either module.

  The rest of the tree was swept for the same class. No other module hardcodes
  a description that reaches a cloud API.

### Fixed — Pulumi runtime and behaviour

- **Removed runtime panics in six components.** `ec2`, `kms`, `security-group`,
  `eks`, `aks` and the `azure-aks` package type-asserted a `pulumi.Input` to a
  concrete type (`args.X.(pulumi.String)`) to apply a default. That panics
  whenever a caller passes an `Output` from another resource — the normal way
  to compose components. Replaced throughout with `nil` checks that preserve
  the Input.

- **`aws/vpc` now creates subnets.** It previously created only the VPC and
  Internet Gateway, then set `PublicSubnetIDs` and `PrivateSubnetIDs` to
  hardcoded empty arrays. Consumers — including the `aws-eks` package, which
  passes `PrivateSubnetIDs` to the EKS cluster — received nothing. Subnets,
  route tables, associations and an optional NAT Gateway are now created, and
  the ID arrays are ordered to match their CIDR arguments.

- **`azure/vnet` now exports real subnet IDs.** Subnets were declared inline on
  the virtual network, which makes them individually unaddressable, and
  `SubnetIDs` was hardcoded empty. `azure-aks` indexed that empty array for the
  AKS node pool subnet. Subnets are now discrete resources with exported IDs.

- **`aws/iam-role` no longer creates resources inside an `ApplyT` callback.**
  Managed policy attachments were registered asynchronously and the returned
  error was discarded. They are now created synchronously so failures reach the
  caller. `ManagedPolicyARNs` changed from `pulumi.StringArrayInput` to
  `[]string` and `CreateInstanceProfile` from `pulumi.BoolInput` to `bool`,
  because both determine how many resources exist.

- **Arguments that were declared but never read are now honoured** across
  `ec2` (`AmiID`, `RootVolumeSizeGB`, `AllowedSSHCidrs`, `AllowedHTTPCidrs`),
  `kms` (`EnableKeyRotation`, `DeletionWindowDays`, `MultiRegion`),
  `security-group` (`AllowAllEgress`), `s3` (`EnableVersioning`,
  `EnableEncryption`, `BlockPublicAccess`, `NoncurrentVersionExpirationDays`),
  `cloudwatch` (`LogRetentionDays`, `CPUAlarmThreshold`, `AlarmEmailEndpoint`),
  `eks` (`NodeDesiredCount`, `NodeMinCount`, `NodeMaxCount`), `rds` (engine,
  version, class, storage, port, retention, and the two safety flags), `aks`
  (`SystemNodeCount`, `EnablePrivateCluster`) and `log-analytics`
  (`RetentionDays`, `Sku`, `EnableContainerInsights`).

- **`aws/eks` node group now waits for its IAM policy attachments.** Without
  `DependsOn`, nodes could launch before they were permitted to join the
  cluster. The cluster likewise now depends on its own policy attachment.
  Also exports `ClusterCaCertificate`, needed to build a kubeconfig.

- **`aws/rds` no longer sets `SkipFinalSnapshot` and `DeletionProtection` to
  hardcoded values.** Both are configurable, and `PubliclyAccessible` is
  explicitly `false`.

- `azure/nsg` dropped the `NSGARN` field, which duplicated `NSGID` and was
  never registered as an output. Azure resources have no ARNs.
- `azure/log-analytics` now registers `WorkspaceKey` as an output instead of
  assigning it and discarding it.
- `aws/cloudwatch` creates an SNS topic and subscription when
  `AlarmEmailEndpoint` is supplied, so alarms can actually notify.
- `aws-eks` exports `KmsKeyARN` instead of discarding the KMS component.

### Fixed — documentation

- **All 18 Terraform module `README.md` files rewritten against their code.**
  Every input table, output table and usage example was verified against
  `main.tf`, `variables.tf` and `outputs.tf`. The v1.x documentation described
  an earlier design throughout. Most consequential corrections:

  - `aws/rds` documented `deletion_protection = true` and
    `skip_final_snapshot = false`. The real defaults are the **inverse**
    (`false` and `true`), meaning a database a reader believed was protected
    could be destroyed with no final snapshot. Now carries an explicit warning
    rather than a table row. Its example also passed a non-existent
    `security_group_ids`; the module takes `vpc_id` +
    `allowed_security_group_ids` and creates its own security group.
  - `aws/iam` documented an IAM **user** module with groups and `username` /
    `policy_arns`. The module creates an IAM **role** with an optional instance
    profile. Every input and output in that table was fictional.
  - `azure/managed-identity` advertised a `role_assignments` input and claimed
    the module "optionally assigns Azure RBAC roles". Neither the variable nor
    any `azurerm_role_assignment` resource exists. The README now shows how to
    assign roles yourself using the `principal_id` output.
  - `azure/vnet` documented `subnets` as `map(string)`; the real type is
    `list(object({name, address_prefixes, service_endpoints}))`. The documented
    example was a type error.
  - `aws/ec2` claimed the default AMI was Amazon Linux 2023. It resolves
    **Ubuntu 22.04**, which changes the SSH user from `ec2-user` to `ubuntu` —
    a mismatch that presents as `Permission denied (publickey)` and is
    routinely misdiagnosed as a key problem.
  - `azure/nsg` documented `security_rules` as defaulting to `[]`. It defaults
    to allow-HTTPS plus deny-all-inbound, so omitting it produces a restrictive
    NSG rather than an open one.
  - `aws/alb` documented a `certificate_arn` input and an "optional HTTPS
    redirect". Neither exists; the module creates an HTTP listener only.
  - `aws/cloudwatch` omitted the entire `metric_alarms` feature and its
    `alarm_arns` output, and its example passed a full path as
    `log_group_name`, which the module prefixes.

  Behaviour that was undocumented and surprising is now stated explicitly:
  ElastiCache forces transit encryption (clients must use `rediss://`), AKS
  uses Azure CNI so every pod consumes a subnet IP, and `s3.kms_key_arn` /
  `cloudwatch.kms_key_id` both take ARNs rather than key IDs.

- `infra/pulumi/README.md` examples updated for the signature changes above,
  with a table of which `Args` fields are plain Go values rather than Inputs,
  and a section documenting the deliberate differences between the Terraform
  and Pulumi libraries.
- 16 Pulumi components had doc comments pointing at `infra/modules/...`, a path
  deleted in 2.0.0. Corrected to `infra/terraform/modules/...`.
- `aws/iam` and `aws/iam-role` are near-duplicates. Rather than leave that as a
  trap, both READMEs now carry a comparison table explaining which to use.
  Consolidation is deferred.

### Note

`gofmt` violations in `kms.go`, `securitygroup.go` and `cloudwatch.go` were
corrected as part of the rewrites above. The `pulumi-ci` `go-lint` stage runs
`gofmt -l`, which would have failed on the 2.0.0 tree.

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

All resolved in 2.1.0 — prefer that release. Carried over from v1.x and not
addressed by 2.0.0, which was a path-only restructure plus the two new
packages:

- Module `README.md` files describe an earlier design in all 18 modules.
- `aws/rds` and `aws/elasticache` contain a non-ASCII character in an
  `aws_security_group` `description`, which the AWS API rejects on apply.

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

[Unreleased]: https://github.com/rafatusa/enterprise-infra-module/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/rafatusa/enterprise-infra-module/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rafatusa/enterprise-infra-module/releases/tag/v1.0.0
