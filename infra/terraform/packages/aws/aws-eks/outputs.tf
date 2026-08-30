output "vpc_id" {
  description = "ID of the VPC hosting the cluster"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets running the worker nodes"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting bucket objects and log data"
  value       = module.kms.key_arn
}

output "state_bucket_name" {
  description = "Name of the S3 bucket for platform artifacts"
  value       = module.state_bucket.bucket_id
}

output "log_group_name" {
  description = "CloudWatch log group name for the platform"
  value       = module.cloudwatch.log_group_name
}
