output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.ec2.private_ip
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = module.security_group.security_group_id
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms.key_arn
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3.bucket_id
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch log group names"
  value       = module.cloudwatch.log_group_names
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.iam_role.role_arn
}
