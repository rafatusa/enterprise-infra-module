output "instance_id" {
  description = "The EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address (empty string if in a private subnet)"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.this.private_ip
}

output "key_pair_name" {
  description = "Name of the created key pair"
  value       = aws_key_pair.this.key_name
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.this.arn
}
