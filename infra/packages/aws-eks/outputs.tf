###############################################################################
# Package: aws-eks — outputs
###############################################################################

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS secret encryption."
  value       = module.kms.key_arn
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role."
  value       = module.eks_cluster_role.role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role."
  value       = module.eks_node_role.role_arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group for EKS."
  value       = module.cloudwatch.log_group_name
}
