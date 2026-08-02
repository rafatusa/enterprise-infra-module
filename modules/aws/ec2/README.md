# Module: aws/ec2

Creates an AWS EC2 instance with IMDSv2 enforcement, optional EIP, optional IAM instance profile, and encrypted EBS root volume. Resolves the latest Amazon Linux 2023 AMI when no AMI ID is provided.

## Security Defaults

- IMDSv2 enforced (`http_tokens = required`)
- Root EBS volume encrypted by default
- Public IP disabled by default (use `allocate_eip = true` for controlled public access)
