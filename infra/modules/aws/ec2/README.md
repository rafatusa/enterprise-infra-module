# Module: aws/ec2

Provisions an EC2 instance with an optional key pair, IAM instance profile, and Elastic IP.

## Usage

```hcl
module "ec2" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/ec2?ref=v1.0.0"

  project_name          = "my-app"
  environment           = "prod"
  subnet_id             = module.vpc.public_subnet_ids[0]
  security_group_ids    = [module.security_group.security_group_id]
  ssh_public_key        = var.ssh_public_key
  instance_type         = "t3.micro"
  iam_instance_profile  = module.iam_role.instance_profile_name
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `subnet_id` | Subnet to launch the instance into | `string` | — | yes |
| `security_group_ids` | Security group IDs to attach | `list(string)` | — | yes |
| `ssh_public_key` | SSH public key for the EC2 key pair | `string` | — | yes |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `ami_id` | AMI ID (defaults to latest Amazon Linux 2023) | `string` | `""` | no |
| `iam_instance_profile` | IAM instance profile name to attach | `string` | `""` | no |
| `associate_public_ip` | Associate a public IP address | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP address |
| `private_ip` | Private IP address |
| `instance_arn` | ARN of the instance |
