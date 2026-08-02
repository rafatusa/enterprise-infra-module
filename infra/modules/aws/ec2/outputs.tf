output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address (EIP when allocate_eip=true, otherwise ephemeral)."
  value       = var.allocate_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "ami_id" {
  description = "AMI ID resolved and used for this instance."
  value       = local.resolved_ami
}
