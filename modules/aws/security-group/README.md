# Module: aws/security-group

Creates an AWS Security Group with dynamic ingress and egress rules defined as structured variable input.

## Usage

```hcl
module "app_sg" {
  source = "github.com/your-org/terraform-enterprise-modules//modules/aws/security-group?ref=v1.0.0"

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
}
```
