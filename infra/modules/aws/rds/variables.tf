variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string
  default     = null
}

variable "engine" {
  description = "Database engine: postgres, mysql."
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "engine must be 'postgres' or 'mysql'."
  }
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB (0 disables autoscaling)."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
  default     = null
}

variable "db_username" {
  description = "Master database username."
  type        = string
  default     = null
}

variable "db_password" {
  description = "Master database password. Must be provided via TF_VAR_db_password; do not hardcode."
  type        = string
  sensitive   = true
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS DB subnet group (at least 2 in different AZs)."
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to associate with the RDS instance."
  type        = list(string)
  default     = null
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups (0 disables backups)."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection on the RDS instance."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when deleting the DB."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for storage encryption."
  type        = string
  default     = ""
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
