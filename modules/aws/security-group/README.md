# aws/security-group

Provisions a configurable AWS Security Group with dynamic ingress and egress rules.

## Usage

```hcl
module "sg" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/security-group?ref=v1.1.0"

  name        = "my-project-app"
  project     = "my-project"
  environment = "production"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
  ]

  egress_rules = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] },
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Security group name | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `vpc_id` | VPC ID | `string` | — | yes |
| `ingress_rules` | List of ingress rule objects | `list(object)` | `[]` | no |
| `egress_rules` | List of egress rule objects | `list(object)` | allow all | no |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
