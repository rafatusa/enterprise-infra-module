output "replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = aws_elasticache_replication_group.this.id
}

output "primary_endpoint_address" {
  description = "Primary endpoint address for read/write"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for read replicas"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "cache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = aws_security_group.cache.id
}
