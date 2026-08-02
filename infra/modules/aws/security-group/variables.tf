variable "name" {
  description = "Name for the security group."
  type        = string
  default     = null
}

variable "description" {
  description = "Human-readable description for the security group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID in which to create the security group."
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "List of ingress rule objects. Each object: { from_port, to_port, protocol, cidr_blocks?, security_group_ids?, description? }"
  type = list(object({
    from_port          = number
    to_port            = number
    protocol           = string
    cidr_blocks        = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    description        = optional(string, "")
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rule objects. Same schema as ingress_rules. Defaults to allow-all egress."
  type = list(object({
    from_port          = number
    to_port            = number
    protocol           = string
    cidr_blocks        = optional(list(string), [])
    security_group_ids = optional(list(string), [])
    description        = optional(string, "")
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
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
