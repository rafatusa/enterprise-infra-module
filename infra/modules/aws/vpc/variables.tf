variable "name" {
  description = "Name prefix for all resources in this VPC."
  type        = string
  default     = null
}

variable "cidr_block" {
  description = "Primary IPv4 CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR notation."
  }
}

variable "azs" {
  description = "List of Availability Zones to use (must be 2 or 3)."
  type        = list(string)
  default     = null

  validation {
    condition     = var.azs == null || (length(var.azs) >= 2 && length(var.azs) <= 3)
    error_message = "Provide between 2 and 3 Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = null
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)."
  type        = list(string)
  default     = null
}

variable "enable_nat_gateway" {
  description = "Deploy a NAT Gateway to allow private subnets outbound internet access."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimisation; reduces HA)."
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch log group retention in days for VPC Flow Logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}

variable "project" {
  description = "Project identifier applied as a tag to every resource."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label (e.g. production, staging)."
  type        = string
  default     = "production"
}
