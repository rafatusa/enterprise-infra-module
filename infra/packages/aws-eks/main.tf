###############################################################################
# Package: aws-eks
# Purpose: Complete production EKS environment — VPC, IAM roles, KMS,
#          security groups, EKS cluster, CloudWatch logging.
#          Consumers reference: github.com/org/terraform-enterprise-modules//infra/packages/aws-eks?ref=v1.0.0
###############################################################################

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# VPC
###############################################################################
module "vpc" {
  source = "../../modules/aws/vpc"

  name                 = "${var.cluster_name}-vpc"
  cidr_block           = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_vpc_flow_logs = true

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# KMS key for EKS secret encryption
###############################################################################
module "kms" {
  source = "../../modules/aws/kms"

  name        = "${var.cluster_name}-eks"
  description = "KMS key for EKS cluster ${var.cluster_name} secret encryption"
  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# IAM — EKS cluster role
###############################################################################
module "eks_cluster_role" {
  source = "../../modules/aws/iam-role"

  name                   = "${var.cluster_name}-cluster-role"
  assume_role_principals = ["eks.amazonaws.com"]
  assume_role_type       = "Service"
  managed_policy_arns    = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# IAM — EKS node role
###############################################################################
module "eks_node_role" {
  source = "../../modules/aws/iam-role"

  name                   = "${var.cluster_name}-node-role"
  assume_role_principals = ["ec2.amazonaws.com"]
  assume_role_type       = "Service"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# Security group — additional cluster SG
###############################################################################
module "eks_sg" {
  source = "../../modules/aws/security-group"

  name        = "${var.cluster_name}-cluster-sg"
  description = "Additional security group for EKS cluster ${var.cluster_name}"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = []
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# EKS cluster
###############################################################################
module "eks" {
  source = "../../modules/aws/eks"

  cluster_name              = var.cluster_name
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_role_arn          = module.eks_cluster_role.role_arn
  node_role_arn             = module.eks_node_role.role_arn
  cluster_security_group_id = module.eks_sg.security_group_id
  kms_key_arn               = module.kms.key_arn

  endpoint_private_access = true
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  node_groups = var.node_groups

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# CloudWatch — EKS control plane logs
###############################################################################
module "cloudwatch" {
  source = "../../modules/aws/cloudwatch"

  name               = "${var.cluster_name}-eks"
  log_retention_days = var.log_retention_days
  kms_key_id         = module.kms.key_arn

  project     = var.project
  environment = var.environment
  tags        = var.tags
}
