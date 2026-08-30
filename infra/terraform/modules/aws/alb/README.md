# Module: aws/alb

Creates an Application Load Balancer with an HTTP listener, target group, and optional HTTPS redirect.

## Usage

```hcl
module "alb" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/alb?ref=v2.0.0"

  project_name      = "my-app"
  environment       = "prod"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.security_group_id
  target_port       = 8080
  health_check_path = "/health"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `vpc_id` | VPC ID for the target group | `string` | — | yes |
| `subnet_ids` | Public subnet IDs for the ALB | `list(string)` | — | yes |
| `security_group_id` | Security group ID for the ALB | `string` | — | yes |
| `target_port` | Port the backend instances listen on | `number` | `80` | no |
| `health_check_path` | HTTP path for health checks | `string` | `"/"` | no |
| `certificate_arn` | ACM certificate ARN for HTTPS listener | `string` | `""` | no |
| `internal` | Create an internal (non-internet-facing) ALB | `bool` | `false` | no |

## Outputs

| Name | Description |
|---|---|
| `alb_dns_name` | DNS name of the load balancer |
| `alb_arn` | ARN of the load balancer |
| `target_group_arn` | ARN of the default target group |
| `alb_zone_id` | Hosted zone ID for Route 53 alias records |
