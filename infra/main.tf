###############################################################################
# infra/main.tf
# terraform-enterprise-modules — CI state sentinel
#
# This project IS the Terraform module library. No cloud resources are
# provisioned here. This file exists solely so the UDAP platform's provision
# stage can init and apply against the platform-managed state bucket.
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  backend "s3" {}

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Sentinel resource — marks this state as live without provisioning anything.
resource "null_resource" "library_sentinel" {
  triggers = {
    library_version = var.library_version
  }
}
