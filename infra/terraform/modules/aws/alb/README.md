# Module: aws/alb

Creates an Application Load Balancer with a target group and an **HTTP listener on port
80**.

## Usage

```hcl
module "alb" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/alb?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]

  target_port          = 8080
  health_check_path    = "/healthz"
  health_check_matcher = "200"
}
```

## HTTP only — no TLS

This module creates **one listener: HTTP on port 80**. There is no `certificate_arn`
input, no HTTPS listener, and no HTTP→HTTPS redirect. Earlier documentation described an
"optional HTTPS redirect"; it was never implemented.

To terminate TLS, add the listener in your own configuration against the exported ARNs:

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.alb_arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.this.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arn
  }
}
```

You can also convert the module's port-80 listener into a redirect by importing and
overriding it, but adding a separate HTTPS listener as above is simpler.

## Subnets

`subnet_ids` must span **at least two availability zones** — an ALB with subnets in a
single AZ fails to create. Pass the full list from `module.vpc.public_subnet_ids` (or the
private list when `internal = true`).

## Target registration

The module creates the target group but does **not** register targets. Attach instances
or ECS services yourself using the `target_group_arn` output.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `internal` | Set `true` for an internal (private) ALB | `bool` | `false` | no |
| `subnet_ids` | Subnet IDs for the ALB (needs 2 or more AZs) | `list(string)` | `null` | no |
| `security_group_ids` | Security group IDs to attach to the ALB | `list(string)` | `[]` | no |
| `vpc_id` | VPC ID for the target group | `string` | `null` | no |
| `target_port` | Port the target instances/containers listen on | `number` | `80` | no |
| `target_protocol` | Protocol for the target group (`HTTP` or `HTTPS`) | `string` | `"HTTP"` | no |
| `health_check_path` | Path for ALB health checks | `string` | `"/"` | no |
| `health_check_matcher` | HTTP response codes accepted as healthy | `string` | `"200-299"` | no |
| `deletion_protection` | Enable ALB deletion protection | `bool` | `false` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

Note this is `security_group_ids` (a list), not `security_group_id`. Although
`subnet_ids` and `vpc_id` default to `null` so the module can be planned in isolation,
the ALB cannot be created without them.

## Outputs

| Name | Description |
|---|---|
| `alb_arn` | ALB ARN |
| `alb_dns_name` | ALB DNS name |
| `alb_zone_id` | ALB hosted zone ID (for Route 53 alias records) |
| `target_group_arn` | Target group ARN — register your targets against this |
| `http_listener_arn` | HTTP listener ARN |

## Notes

- `drop_invalid_header_fields` is hardcoded to `true`.
- Health checks: 30s interval, 5s timeout, 2 checks to become healthy or unhealthy.
- The target group uses `create_before_destroy`, so port/protocol changes do not deadlock
  against the listener.
