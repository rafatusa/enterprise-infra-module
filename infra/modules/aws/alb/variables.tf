variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "internal" {
  description = "Set true for an internal (private) ALB"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Public subnet IDs for the ALB (needs ≥2 AZs)"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the ALB"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for the target group"
  type        = string
  default     = null
}

variable "target_port" {
  description = "Port the target instances/containers listen on"
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Protocol for the target group (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP response codes to accept for healthy targets"
  type        = string
  default     = "200-299"
}

variable "deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
