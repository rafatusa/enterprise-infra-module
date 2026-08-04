# aws/vpc

Provisions a production-grade AWS VPC with public and private subnets, Internet Gateway, NAT Gateways, and VPC Flow Logs.

## Usage

```hcl
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/vpc?ref=v1.1.0"

  name        = "my-project"
  project     = "my-project"
  environment = "production"

  cidr_block           = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource name prefix | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `cidr_block` | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| `azs` | Availability zones | `list(string)` | — | yes |
| `public_subnet_cidrs` | Public subnet CIDRs | `list(string)` | — | yes |
| `private_subnet_cidrs` | Private subnet CIDRs | `list(string)` | — | yes |
| `enable_nat_gateway` | Enable NAT Gateway | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `vpc_cidr_block` | VPC CIDR block |
