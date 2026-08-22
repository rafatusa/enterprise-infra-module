plugin "aws" {
  enabled = true
  version = "0.38.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Reusable modules expose parameter_group_name as an overridable variable.
# The default "default.redis7" is intentional — callers can supply a custom group.
rule "aws_elasticache_replication_group_default_parameter_group" {
  enabled = false
}
