###############################################################################
# modules/aws/security-group/main.tf
# Reusable dynamic Security Group module
###############################################################################

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws/security-group"
    },
    var.tags
  )
}

resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = var.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.ingress_rules :
    "${idx}-${rule.from_port}-${rule.to_port}" => rule
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids[0] : null
}

resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.egress_rules :
    "${idx}-${rule.from_port}-${rule.to_port}" => rule
  }

  type              = "egress"
  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids[0] : null
}
