variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy."
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "VPC ID in which to place the EKS cluster."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS control plane and node groups."
  type        = list(string)
  default     = null
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS control plane."
  type        = string
  default     = null
}

variable "node_role_arn" {
  description = "ARN of the IAM role for managed node groups."
  type        = string
  default     = null
}

variable "cluster_security_group_id" {
  description = "Additional security group ID to attach to the EKS control plane (optional)."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting Kubernetes secrets."
  type        = string
  default     = ""
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled."
  type        = bool
  default     = true
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

variable "cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days for EKS control plane logs."
  type        = number
  default     = 30
}

variable "node_groups" {
  description = "Map of node group configurations."
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
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 5
      disk_size      = 50
    }
  }
}

variable "project" {
  description = "Project identifier applied as a tag."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "production"
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default     = {}
}
