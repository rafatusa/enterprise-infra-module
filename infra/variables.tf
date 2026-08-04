###############################################################################
# infra/variables.tf
# ec2-from-modules — only two inputs required from the operator
###############################################################################

variable "project_name" {
  description = "Project name — used as resource name prefix and tag value. Must be lowercase alphanumeric + hyphens."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into (e.g. us-east-1, eu-west-1)."
  type        = string
  default     = "us-east-1"
}

# Injected by the platform at deploy time — not supplied by the operator.
variable "ssh_public_key" {
  description = "RSA public key injected by the UDAP platform (SSH_PUBLIC_KEY secret). Do not set manually."
  type        = string
  sensitive   = true
  default     = null
}
