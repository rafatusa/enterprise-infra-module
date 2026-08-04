# Module: aws/vpc

Provisions a production-ready AWS VPC with public and private subnets across multiple Availability Zones, Internet Gateway, NAT Gateways, route tables, and optional VPC Flow Logs.

## Usage

```hcl
module "vpc" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.1.0"

  name    = "my-app"
  project = "my-project"

  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false  # true for dev/staging to save cost
  enable_vpc_flow_logs = true

  environment = "production"
  tags        = { Team = "platform" }
}
```

## Resources Created

| Resource | Description |
|---|---|
| `aws_vpc` | Primary VPC |
| `aws_internet_gateway` | Internet Gateway attached to the VPC |
| `aws_subnet` (public × N) | Public subnets with auto-assign public IP |
| `aws_subnet` (private × N) | Private subnets |
| `aws_eip` × N | Elastic IPs for NAT Gateways |
| `aws_nat_gateway` × N | NAT Gateways in public subnets |
| `aws_route_table` (public) | Route table for public subnets → IGW |
| `aws_route_table` (private × N) | Route tables for private subnets → NAT |
| `aws_flow_log` | VPC Flow Log (if enabled) |
| `aws_cloudwatch_log_group` | Flow log destination (if enabled) |
| `aws_iam_role` + policy | Flow log delivery role (if enabled) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | VPC name prefix | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| cidr_block | VPC CIDR | `string` | `10.0.0.0/16` | no |
| azs | Availability zones | `list(string)` | — | yes |
| public_subnet_cidrs | Public subnet CIDRs | `list(string)` | — | yes |
| private_subnet_cidrs | Private subnet CIDRs | `list(string)` | — | yes |
| enable_nat_gateway | Create NAT Gateways | `bool` | `true` | no |
| single_nat_gateway | One NAT GW for all AZs | `bool` | `false` | no |
| enable_vpc_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| environment | Environment tag | `string` | `production` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `nat_public_ips` | Public IPs of NAT Gateways |

## Security Notes

- Flow logs are **enabled by default** — disable only with explicit justification.
- Private subnets have no direct internet route; outbound traffic goes through NAT.
- Public subnets are tagged `kubernetes.io/role/elb=1` for ALB discovery.
- Private subnets are tagged `kubernetes.io/role/internal-elb=1` for internal ALB.
