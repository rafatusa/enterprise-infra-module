variable "name" {
  description = "Name for the EC2 instance and related resources."
  type        = string
  default     = null
}

variable "ami_id" {
  description = "AMI ID to launch. If empty, the module resolves the latest Amazon Linux 2023 AMI."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID in which to launch the instance."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID (used to scope the security group)."
  type        = string
  default     = null
}

variable "key_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of additional security group IDs to attach."
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP with the instance."
  type        = bool
  default     = false
}

variable "allocate_eip" {
  description = "Allocate an Elastic IP and associate it with the instance."
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach."
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script (base64-encoded) for instance bootstrap."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type (gp3 recommended)."
  type        = string
  default     = "gp3"
}

variable "root_volume_encrypted" {
  description = "Encrypt the root EBS volume."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption (uses AWS-managed key when empty)."
  type        = string
  default     = ""
}

variable "enable_termination_protection" {
  description = "Enable EC2 termination protection."
  type        = bool
  default     = false
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
