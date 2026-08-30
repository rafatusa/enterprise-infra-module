# Module: aws/security-group

Creates a security group with configurable ingress and egress rules.

Rules are supplied as lists of objects rather than as fixed port toggles, so the
module can express any rule set without new variables. Egress defaults to
allow-all; override `egress_rules` to restrict it.

## Usage

```hcl
module "security_group" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/security-group?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"
  name         = "web"
  description  = "Web tier security group"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH from the corporate range"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  tags = {
    Owner = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | n/a | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `name` | Short name appended to the security group (e.g. app, db, alb) | `string` | `"app"` | no |
| `description` | Security group description | `string` | `"Managed by Terraform"` | no |
| `vpc_id` | VPC ID | `string` | `null` | no |
| `ingress_rules` | List of ingress rules | `list(object)` | `[]` | no |
| `egress_rules` | List of egress rules | `list(object)` | allow-all | no |
| `tags` | Additional tags | `map(string)` | `{}` | no |

Each rule object has the shape:

```hcl
{
  description = string
  from_port   = number
  to_port     = number
  protocol    = string
  cidr_blocks = list(string)
}
```

Rule `description` values must be ASCII and match AWS's allowed character set;
non-ASCII punctuation such as an em-dash is rejected at apply time.

## Outputs

| Name | Description |
|---|---|
| `security_group_id` | ID of the security group |
| `security_group_arn` | ARN of the security group |
| `security_group_name` | Name of the security group |
