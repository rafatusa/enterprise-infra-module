terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  default_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  resolved_policy = var.assume_role_policy != null ? var.assume_role_policy : local.default_assume_role_policy
}

resource "aws_iam_role" "this" {
  name               = "${var.project_name}-${var.environment}-${var.role_name}"
  assume_role_policy = local.resolved_policy

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.role_name}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy != null ? 1 : 0

  name   = "${var.project_name}-${var.environment}-${var.role_name}-inline"
  role   = aws_iam_role.this.id
  policy = var.inline_policy
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.project_name}-${var.environment}-${var.role_name}-profile"
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
