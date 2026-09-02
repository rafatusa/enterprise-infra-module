# Module: aws/ec2

Launches a single EC2 instance with an encrypted `gp3` root volume, IMDSv2 enforced, and
a dedicated key pair created from the public key you supply.

## Usage

```hcl
module "app" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/ec2?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.app_sg.security_group_id]
  ssh_public_key     = file("~/.ssh/id_rsa.pub")

  instance_type    = "t3.small"
  root_volume_size = 40
}
```

## Default AMI is Ubuntu, not Amazon Linux

When `ami_id` is `null` (the default) the module resolves the **latest Ubuntu 22.04 LTS
(Jammy)** image from Canonical (owner `099720109477`).

This matters for your login user:

| AMI | SSH user |
|---|---|
| Ubuntu 22.04 (the default here) | `ubuntu` |
| Amazon Linux 2023 / RHEL | `ec2-user` |
| Debian | `admin` |

Earlier documentation claimed the default was Amazon Linux 2023. It is not. If you
connect as `ec2-user` against a default-AMI instance you will get
`Permission denied (publickey)` — the key is fine, the user is wrong.

Pass `ami_id` explicitly to use a different image, and set your SSH user to match.

## Public IP

The module does not manage public IP association. The instance receives one only if its
subnet has `map_public_ip_on_launch = true` — which the `aws/vpc` module sets on public
subnets. In a private subnet the `public_ip` output is an empty string.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming and tagging | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `ami_id` | AMI ID for the instance. Resolves latest Ubuntu 22.04 LTS when `null`. | `string` | `null` | no |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `subnet_id` | Subnet ID to launch the instance in | `string` | `null` | no |
| `security_group_ids` | Security group IDs to attach to the instance | `list(string)` | `[]` | no |
| `ssh_public_key` | SSH public key material for the key pair (sensitive) | `string` | `null` | no |
| `iam_instance_profile` | IAM instance profile name to attach (`null` to skip) | `string` | `null` | no |
| `root_volume_type` | Root EBS volume type | `string` | `"gp3"` | no |
| `root_volume_size` | Root EBS volume size in GiB | `number` | `20` | no |
| `tags` | Additional tags merged onto every resource | `map(string)` | `{}` | no |

Although `subnet_id` and `ssh_public_key` default to `null` so the module can be planned
in isolation, the instance is not usable without them. Treat them as effectively
required.

## Outputs

| Name | Description |
|---|---|
| `instance_id` | The EC2 instance ID |
| `instance_arn` | EC2 instance ARN |
| `public_ip` | Public IP address (empty string if in a private subnet) |
| `private_ip` | Private IP address |
| `key_pair_name` | Name of the created key pair |

## Notes

- The root volume is always encrypted and deleted on termination.
- IMDSv2 is enforced (`http_tokens = "required"`) with a hop limit of 1.
- The key pair is named `<project_name>-<environment>-key`. Changing `ssh_public_key`
  replaces the key pair, which does **not** update a running instance — the instance
  must be replaced in the same apply.
