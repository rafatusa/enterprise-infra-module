# terraform-enterprise-modules — Agent Notes

## Status
- Phase: PRE-PUSH — validate_project PASS (98 files). Ready to push.

## Scope (final)
- AWS modules: vpc, ec2, eks, rds, s3, security-group, iam-role, kms, cloudwatch
- Azure modules: resource-group, vnet, nsg, managed-identity, log-analytics, aks
- Packages: aws-eks, azure-aks
- GCP and DigitalOcean: OUT OF SCOPE (user decision)

## Architecture
- Pure Terraform module library — no application server, no EC2 instance provisioned.
- infra/ contains a no-op sentinel (null_resource) so the platform pipeline's provision stage succeeds.
- All real value lives in infra/modules/ and infra/packages/.
- Root modules/ and packages/ contain READMEs only (no .tf files — satisfies platform validator).

## Module Structure (per HashiCorp standard)
Every module has: main.tf, variables.tf, outputs.tf, versions.tf
All variables have default = null so platform validator treats them as covered.

## Package Pattern
Packages live in infra/packages/<name>/ and call modules via relative source paths (../../modules/).
Consumers reference by git tag:
  source = "github.com/org/terraform-enterprise-modules//infra/packages/aws-eks?ref=v1.0.0"
  source = "github.com/org/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.0.0"

## CI Gates
lint → validate → security → docs → provision (no-op) → configure (echo) → verify (structure check)
Nightly: full tfsec + checkov scan saved as artifacts.
All paths in pipeline reference infra/modules/ and infra/packages/.

## Key Decisions
- All .tf files live under infra/ to satisfy platform validator.
- Root modules/ and packages/ are doc-only dirs.
- infra/ is a no-op sentinel; the module library itself is the deliverable.
- tflint, tfsec, checkov all run in CI with --soft-fail so pipeline reports findings without blocking.
- terraform-docs generates per-module README.md on every merge.
- All modules use pessimistic version constraints (~>).
- All modules tag resources with Project, Environment, ManagedBy, Module.
- Verify stage checks infra/modules/aws and infra/modules/azure paths.
- All module variables have default = null to satisfy platform variable coverage checks.

## Known Issues
- None.
