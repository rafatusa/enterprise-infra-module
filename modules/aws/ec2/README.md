# aws/ec2

Provisions an EC2 instance with IMDSv2 enforcement, encrypted EBS, optional Elastic IP, and IAM instance profile.

## Usage

```hcl
module "ec2" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/ec2?ref=v1.1.0"

  name               = "my-project"
  project            = "my-project"
  environment        = "production"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security_group.security_group_id]
  ssh_public_key     = var.ssh_public_key
  instance_type      = "t3.medium"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource name prefix | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `subnet_id` | Subnet to launch the instance in | `string` | — | yes |
| `security_group_ids` | List of security group IDs | `list(string)` | — | yes |
| `ssh_public_key` | SSH public key for key pair | `string` | — | yes |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `associate_public_ip` | Associate a public IP | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | EC2 instance ID |
| `public_ip` | Public IP address (if assigned) |
| `private_ip` | Private IP address |
| `security_group_id` | Security group ID |
