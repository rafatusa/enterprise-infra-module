###############################################################################
# Package: aws-eks — input variables
###############################################################################

variable "cluster_name" {
  description = "Name of the EKS cluster. Used as a prefix for all resources."
  type        = string
  default     = null
}

variable "project" {
  description = "Project identifier applied as a tag to all resources."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of 2 or 3 Availability Zones for VPC subnets."
  type        = list(string)
  default     = null
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

variable "kubernetes_version" {
  description = "Kubernetes version to deploy on EKS."
  type        = string
  default     = "1.33"
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Map of node group configurations passed to the eks module."
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = optional(number, 50)
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    default = {
      instance_types = ["t3.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      disk_size      = 50
    }
  }
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
