variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# --- Networking ------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones - EKS requires at least two"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets - one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets - one per AZ. Worker nodes run here."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway so private subnets can reach the internet. Required for nodes to pull images."
  type        = bool
  default     = true
}

# --- Encryption ------------------------------------------------------------

variable "kms_deletion_window_in_days" {
  description = "Days to wait before KMS key deletion after it is scheduled (7-30)"
  type        = number
  default     = 30
}

# --- Object storage --------------------------------------------------------

variable "state_bucket_name" {
  description = "S3 bucket name for platform artifacts. Defaults to '<project>-<env>-data' when null."
  type        = string
  default     = null
}

variable "state_bucket_expiration_days" {
  description = "Days after which bucket objects expire (0 = no lifecycle rule)"
  type        = number
  default     = 0
}

# --- Cluster ---------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes control-plane version"
  type        = string
  default     = "1.29"
}

variable "endpoint_public_access" {
  description = "Allow public access to the Kubernetes API server endpoint"
  type        = bool
  default     = true
}

variable "instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Node capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

# --- Observability ---------------------------------------------------------

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days (0 = never expire)"
  type        = number
  default     = 30
}

variable "metric_alarms" {
  description = "CloudWatch metric alarms to create alongside the log group"
  type = list(object({
    alarm_name          = string
    alarm_description   = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_actions       = list(string)
    ok_actions          = list(string)
  }))
  default = []
}

# --- Tagging ---------------------------------------------------------------

variable "tags" {
  description = "Additional tags merged onto every resource in the package"
  type        = map(string)
  default     = {}
}
