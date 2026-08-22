terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.environment}-${var.name}-sg"
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-${var.name}-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, rule in var.ingress_rules : tostring(idx) => rule }

  type              = "ingress"
  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "egress" {
  for_each = { for idx, rule in var.egress_rules : tostring(idx) => rule }

  type              = "egress"
  security_group_id = aws_security_group.this.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}
