###############################################################################
# infra/main.tf
# ec2-from-modules — EC2 instance provisioned via enterprise module library
#
# Inputs:  var.project_name, var.aws_region  (the only two inputs required)
# Modules: vpc + ec2 + security-group sourced from terraform-enterprise-modules
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################################
# VPC — single AZ, one public subnet (minimal; extend via package for HA)
###############################################################################
module "vpc" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/vpc?ref=v1.0.0"

  name    = var.project_name
  project = var.project_name

  azs                  = ["${var.aws_region}a"]
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24"]

  enable_nat_gateway   = false   # single public subnet — no NAT needed
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
    ConsumedBy  = "ec2-from-modules"
  }
}

###############################################################################
# Security Group — SSH (22) + HTTP (80) inbound
###############################################################################
module "sg" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/security-group?ref=v1.0.0"

  name    = "${var.project_name}-ec2-sg"
  project = var.project_name
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound"
    }
  ]

  tags = {
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

###############################################################################
# EC2 Instance
###############################################################################
module "ec2" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/ec2?ref=v1.0.0"

  name      = var.project_name
  project   = var.project_name
  subnet_id = module.vpc.public_subnet_ids[0]
  vpc_id    = module.vpc.vpc_id

  instance_type          = "t3.micro"
  ami_id                 = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [module.sg.security_group_id]
  associate_public_ip    = true

  root_volume_size = 20
  root_volume_type = "gp3"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>${var.project_name} — deployed via terraform-enterprise-modules</h1>" \
      > /var/www/html/index.html
  EOF
  )

  tags = {
    Project     = var.project_name
    Environment = "production"
    ManagedBy   = "terraform"
    ConsumedBy  = "ec2-from-modules"
  }
}

###############################################################################
# Latest Ubuntu 22.04 LTS AMI
###############################################################################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# Key Pair — injected from platform secret
###############################################################################
resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-deploy-key"
  public_key = var.ssh_public_key

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
