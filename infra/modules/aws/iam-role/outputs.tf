output "role_arn" {
  description = "The ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "The name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "The ID of the IAM role."
  value       = aws_iam_role.this.id
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile (non-empty only when ec2.amazonaws.com is a principal)."
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].arn : ""
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile."
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : ""
}
