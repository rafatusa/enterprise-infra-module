###############################################################################
# modules/aws/iam-role/main.tf
# Reusable IAM Role module
###############################################################################

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws/iam-role"
    },
    var.tags
  )
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  path                 = var.path
  max_session_duration = var.max_session_duration

  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          (var.assume_role_type) = length(var.assume_role_principals) == 1 ? var.assume_role_principals[0] : var.assume_role_principals
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json != "" ? 1 : 0
  name   = var.inline_policy_name
  role   = aws_iam_role.this.id
  policy = var.inline_policy_json
}

resource "aws_iam_instance_profile" "this" {
  count = contains(var.assume_role_principals, "ec2.amazonaws.com") ? 1 : 0
  name  = var.name
  role  = aws_iam_role.this.name
  tags  = local.common_tags
}
