output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (empty string if not created)"
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (null if not created)"
  value       = length(aws_iam_instance_profile.this) > 0 ? aws_iam_instance_profile.this[0].name : null
}
