terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "RDS access - managed by Terraform"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "DB port from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project_name}-${var.environment}-${replace(var.family, ".", "-")}"
  family = var.family

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-pg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-${var.environment}-db"
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  port                   = var.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  storage_type          = "gp3"
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-db"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
