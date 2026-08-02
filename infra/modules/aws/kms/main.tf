###############################################################################
# modules/aws/kms/main.tf
# Reusable AWS KMS key module
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws/kms"
    },
    var.tags
  )

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "RootAccountFullAccess"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${local.account_id}:root"
          }
          Action   = "kms:*"
          Resource = "*"
        }
      ],
      length(var.key_administrators) > 0 ? [
        {
          Sid    = "KeyAdministrators"
          Effect = "Allow"
          Principal = {
            AWS = var.key_administrators
          }
          Action = [
            "kms:Create*", "kms:Describe*", "kms:Enable*",
            "kms:List*", "kms:Put*", "kms:Update*",
            "kms:Revoke*", "kms:Disable*", "kms:Get*",
            "kms:Delete*", "kms:TagResource", "kms:UntagResource",
            "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"
          ]
          Resource = "*"
        }
      ] : [],
      length(var.key_users) > 0 ? [
        {
          Sid    = "KeyUsers"
          Effect = "Allow"
          Principal = {
            AWS = var.key_users
          }
          Action = [
            "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
            "kms:GenerateDataKey*", "kms:DescribeKey"
          ]
          Resource = "*"
        }
      ] : []
    )
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}
