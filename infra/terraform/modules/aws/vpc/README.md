# Module: aws/vpc

Creates a VPC with public and private subnets across multiple availability zones, an Internet Gateway, an optional NAT Gateway, and the associated route tables.

## Usage

```hcl
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/vpc?ref=v2.0.0"

  project_name         = "my-app"
  environment          = "prod"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  azs                  = ["us-east-1a", "us-east-1b"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming and tagging | `string` | — | yes |
| `environment` | Deployment environment (e.g. dev, staging, prod) | `string` | `"dev"` | no |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `azs` | Availability zones (must match the number of subnet CIDRs) | `list(string)` | `["us-east-1a", "us-east-1b"]` | no |
| `public_subnet_cidrs` | CIDR blocks for public subnets, one per AZ | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| `private_subnet_cidrs` | CIDR blocks for private subnets, one per AZ | `list(string)` | `["10.0.10.0/24", "10.0.11.0/24"]` | no |
| `enable_nat_gateway` | Create a NAT Gateway so private subnets can reach the internet | `bool` | `true` | no |
| `tags` | Additional tags merged onto every resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | IDs of the public subnets |
| `private_subnet_ids` | IDs of the private subnets |
| `nat_gateway_id` | ID of the NAT Gateway (`null` when `enable_nat_gateway = false`) |
| `internet_gateway_id` | ID of the Internet Gateway |
