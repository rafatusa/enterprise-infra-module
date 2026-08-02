###############################################################################
# infra/modules/aws/ec2/main.tf
# Reusable AWS EC2 instance module
###############################################################################

locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "aws/ec2"
    },
    var.tags
  )
}

data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  resolved_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id
}

resource "aws_instance" "this" {
  ami                         = local.resolved_ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = var.associate_public_ip
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.instance_profile_name != "" ? var.instance_profile_name : null
  user_data_base64            = var.user_data != "" ? var.user_data : null
  disable_api_termination     = var.enable_termination_protection

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.kms_key_id != "" ? var.kms_key_id : null
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, { Name = var.name })

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_eip" "this" {
  count    = var.allocate_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.name}-eip" })
}
