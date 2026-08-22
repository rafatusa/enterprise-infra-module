# Module: aws/vpc

Creates a VPC with public and private subnets across multiple availability zones, an Internet Gateway, NAT Gateway, and route tables.

## Usage

```hcl
module "vpc" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/vpc?ref=v1.0.0"

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
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment (prod, staging, dev) | `string` | — | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `public_subnet_cidrs` | CIDR blocks for public subnets (one per AZ) | `list(string)` | — | yes |
| `private_subnet_cidrs` | CIDR blocks for private subnets (one per AZ) | `list(string)` | — | yes |
| `azs` | Availability zones to deploy into | `list(string)` | — | yes |
| `enable_nat_gateway` | Create a NAT Gateway for private subnet egress | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `vpc_cidr_block` | CIDR block of the VPC |
| `nat_gateway_ip` | Elastic IP of the NAT Gateway |
