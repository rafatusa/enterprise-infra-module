# =============================================================================
# enterprise-infra-module — example consumer root
# Calls modules from this repo directly; a vending project can replace these
# sources with a versioned Git ref, e.g.:
#   source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/vpc?ref=v1.0.0"
# =============================================================================

terraform {
  backend "s3" {}
}

# ── VPC ─────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/aws/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

# ── Security Group ───────────────────────────────────────────────────────────

module "security_group" {
  source = "./modules/aws/security-group"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  name         = "app"

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = length(var.allowed_ssh_cidrs) > 0 ? var.allowed_ssh_cidrs : ["0.0.0.0/0"]
      description = "SSH — restrict allowed_ssh_cidrs in production"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all egress"
    }
  ]
}

# ── IAM Role ─────────────────────────────────────────────────────────────────

module "iam_role" {
  source = "./modules/aws/iam-role"

  project_name        = var.project_name
  environment         = var.environment
  role_name_suffix    = "ec2"
  assume_role_service = "ec2.amazonaws.com"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

# ── EC2 ──────────────────────────────────────────────────────────────────────

module "ec2" {
  source = "./modules/aws/ec2"

  project_name         = var.project_name
  environment          = var.environment
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.security_group.security_group_id]
  instance_type        = var.ec2_instance_type
  ssh_public_key       = var.ssh_public_key
  iam_instance_profile = module.iam_role.instance_profile_name
}

# ── KMS ──────────────────────────────────────────────────────────────────────

module "kms" {
  source = "./modules/aws/kms"

  project_name = var.project_name
  environment  = var.environment
  key_name     = "app"
  description  = "KMS key for ${var.project_name} ${var.environment} encryption"
}

# ── S3 ───────────────────────────────────────────────────────────────────────

module "s3" {
  source = "./modules/aws/s3"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
}

# ── CloudWatch ───────────────────────────────────────────────────────────────

module "cloudwatch" {
  source = "./modules/aws/cloudwatch"

  project_name   = var.project_name
  environment    = var.environment
  log_group_name = "app"
}
