terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cache-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_security_group" "cache" {
  name        = "${var.project_name}-${var.environment}-cache-sg"
  description = "ElastiCache access - managed by Terraform"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "Redis port from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cache-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.project_name}-${var.environment}-cache"
  description                = "Redis replication group for ${var.project_name}-${var.environment}"
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  port                       = var.port
  parameter_group_name       = var.parameter_group_name
  engine_version             = var.engine_version
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.cache.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = var.num_cache_clusters > 1

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cache"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
