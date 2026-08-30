terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = var.key_policy

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.key_name}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}-${var.key_name}"
  target_key_id = aws_kms_key.this.key_id
}
