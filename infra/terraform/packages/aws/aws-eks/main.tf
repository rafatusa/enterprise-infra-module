/**
 * Package: aws-eks
 *
 * Opinionated EKS platform composed from this repository's AWS modules:
 * vpc + kms + s3 + eks + cloudwatch.
 *
 * Terraform equivalent of infra/pulumi/packages/aws/aws-eks.
 *
 * This is a reusable composition, not a deployable root module: it declares
 * no backend and no provider. The consuming root module owns both.
 */

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Package     = "aws-eks"
      ManagedBy   = "Terraform"
    },
    var.tags,
  )
}

module "vpc" {
  source = "../../../modules/aws/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

module "kms" {
  source = "../../../modules/aws/kms"

  project_name            = var.project_name
  environment             = var.environment
  key_name                = "eks"
  description             = "Encryption key for the ${local.name_prefix} EKS platform"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  tags                    = local.common_tags
}

module "state_bucket" {
  source = "../../../modules/aws/s3"

  project_name       = var.project_name
  environment        = var.environment
  bucket_name        = var.state_bucket_name
  versioning_enabled = true
  kms_key_arn        = module.kms.key_arn
  expiration_days    = var.state_bucket_expiration_days
  tags               = local.common_tags
}

module "eks" {
  source = "../../../modules/aws/eks"

  project_name           = var.project_name
  environment            = var.environment
  kubernetes_version     = var.kubernetes_version
  subnet_ids             = module.vpc.private_subnet_ids
  endpoint_public_access = var.endpoint_public_access
  instance_types         = var.instance_types
  capacity_type          = var.capacity_type
  desired_size           = var.desired_size
  min_size               = var.min_size
  max_size               = var.max_size
  tags                   = local.common_tags
}

module "cloudwatch" {
  source = "../../../modules/aws/cloudwatch"

  project_name      = var.project_name
  environment       = var.environment
  log_group_name    = "eks"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = module.kms.key_arn
  metric_alarms     = var.metric_alarms
  tags              = local.common_tags
}
