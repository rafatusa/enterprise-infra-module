# Module: aws/security-group

Creates an AWS Security Group with dynamic ingress and egress rules defined as structured variable input.

## Usage

```hcl
module "app_sg" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/security-group?ref=v1.1.0"

  name    = "my-app-sg"
  vpc_id  = module.vpc.vpc_id
  project = "my-project"

  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    },
    {
      from_port          = 8080
      to_port            = 8080
      protocol           = "tcp"
      security_group_ids = [module.alb_sg.security_group_id]
      description        = "App port from ALB"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Security group name | `string` | — | yes |
| vpc_id | VPC to create the SG in | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| description | SG description | `string` | `Managed by Terraform` | no |
| environment | Environment tag | `string` | `production` | no |
| ingress_rules | Ingress rule list | `list(object)` | `[]` | no |
| egress_rules | Egress rule list | `list(object)` | `[allow all]` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
