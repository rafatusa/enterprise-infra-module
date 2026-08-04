# Module: aws/ec2

Creates an AWS EC2 instance with IMDSv2 enforcement, optional EIP, optional IAM instance profile, and encrypted EBS root volume. Resolves the latest Amazon Linux 2023 AMI when no AMI ID is provided.

## Usage

```hcl
module "ec2" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/ec2?ref=v1.1.0"

  name               = "my-app"
  project            = "my-project"
  environment        = "production"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.sg.security_group_id]
  ssh_public_key     = var.ssh_public_key

  instance_type    = "t3.micro"
  allocate_eip     = true
  root_volume_size = 20
}
```

## Security Defaults

- IMDSv2 enforced (`http_tokens = required`)
- Root EBS volume encrypted by default
- Public IP disabled by default (use `allocate_eip = true` for controlled public access)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Instance name prefix | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| subnet_id | Subnet to launch into | `string` | — | yes |
| security_group_ids | Security group IDs | `list(string)` | — | yes |
| instance_type | EC2 instance type | `string` | `t3.micro` | no |
| ami_id | AMI ID (latest AL2023 if omitted) | `string` | `null` | no |
| ssh_public_key | SSH public key for access | `string` | `null` | no |
| allocate_eip | Allocate Elastic IP | `bool` | `false` | no |
| root_volume_size | Root EBS size (GB) | `number` | `20` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP (EIP if allocated) |
| `private_ip` | Private IP address |
| `security_group_id` | Primary security group ID |
| `iam_role_arn` | Instance role ARN (if created) |
