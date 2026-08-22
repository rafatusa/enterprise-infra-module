# Module: aws/security-group

Creates a security group with configurable ingress and egress rules.

## Usage

```hcl
module "security_group" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/security-group?ref=v1.0.0"

  project_name      = "my-app"
  environment       = "prod"
  name              = "web"
  vpc_id            = module.vpc.vpc_id
  allowed_ssh_cidrs = ["10.0.0.0/8"]
  allowed_http_cidrs = ["0.0.0.0/0"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `name` | Name suffix for the security group | `string` | — | yes |
| `vpc_id` | VPC to create the security group in | `string` | — | yes |
| `allowed_ssh_cidrs` | CIDRs allowed on port 22 | `list(string)` | `["0.0.0.0/0"]` | no |
| `allowed_http_cidrs` | CIDRs allowed on port 80 | `list(string)` | `["0.0.0.0/0"]` | no |
| `allowed_https_cidrs` | CIDRs allowed on port 443 | `list(string)` | `["0.0.0.0/0"]` | no |
| `egress_cidr` | CIDR for the catch-all egress rule | `string` | `"0.0.0.0/0"` | no |

## Outputs

| Name | Description |
|---|---|
| `security_group_id` | ID of the security group |
| `security_group_arn` | ARN of the security group |
