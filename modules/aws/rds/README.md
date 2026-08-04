# aws/rds

Provisions an RDS PostgreSQL instance with a DB subnet group, security group, parameter group, and encrypted storage.

## Usage

```hcl
module "rds" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/rds?ref=v1.1.0"

  name               = "my-project"
  project            = "my-project"
  environment        = "production"
  subnet_ids         = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  app_security_group = module.ec2.security_group_id

  db_name     = "appdb"
  db_username = "appuser"
  db_password = var.db_password   # passed via TF_VAR_db_password secret
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Resource name prefix | `string` | — | yes |
| `project` | Project tag value | `string` | — | yes |
| `environment` | Environment tag value | `string` | — | yes |
| `subnet_ids` | Private subnet IDs for DB subnet group | `list(string)` | — | yes |
| `vpc_id` | VPC ID for security group | `string` | — | yes |
| `app_security_group` | App server SG allowed to reach the DB | `string` | — | yes |
| `db_name` | Initial database name | `string` | — | yes |
| `db_username` | Master username | `string` | — | yes |
| `db_password` | Master password (use a secret) | `string` | — | yes |
| `instance_class` | RDS instance class | `string` | `"db.t3.micro"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `endpoint` | RDS endpoint address |
| `port` | Database port |
| `db_name` | Database name |
| `security_group_id` | RDS security group ID |
