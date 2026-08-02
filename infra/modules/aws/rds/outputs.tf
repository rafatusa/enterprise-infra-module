output "db_instance_id" {
  description = "RDS instance ID."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.this.arn
}

output "db_endpoint" {
  description = "Connection endpoint for the RDS instance (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "db_host" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username for the database."
  value       = aws_db_instance.this.username
}

output "subnet_group_name" {
  description = "Name of the DB subnet group."
  value       = aws_db_subnet_group.this.name
}
