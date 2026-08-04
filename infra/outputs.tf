###############################################################################
# infra/outputs.tf
###############################################################################

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

output "vpc_id" {
  description = "VPC ID created by the vpc module"
  value       = module.vpc.vpc_id
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = module.sg.security_group_id
}
