variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "engine" {
  description = "Database engine (postgres, mysql, mariadb, ...)"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "15.4"
}

variable "family" {
  description = "DB parameter group family (e.g. postgres15)"
  type        = string
  default     = "postgres15"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = null
}

variable "username" {
  description = "Master DB username"
  type        = string
  default     = null
}

variable "password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
  default     = null
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling in GiB"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for HA"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group (multi-AZ needs ≥2)"
  type        = list(string)
  default     = null
}

variable "vpc_id" {
  description = "VPC ID for the RDS security group"
  type        = string
  default     = null
}

variable "allowed_security_group_ids" {
  description = "Security group IDs that may connect to the DB"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Automated backup retention in days (0 = disabled)"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false for production)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent accidental deletion via API/console"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
