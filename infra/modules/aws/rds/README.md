# Module: aws/rds

Provisions an RDS database instance inside a private DB subnet group, with optional Multi-AZ and deletion protection.

## Usage

```hcl
module "rds" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/modules/aws/rds?ref=v1.0.0"

  project_name       = "my-app"
  environment        = "prod"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_group.security_group_id]
  db_name            = "appdb"
  username           = "admin"
  password           = var.db_password
  instance_class     = "db.t3.micro"
  engine             = "postgres"
  engine_version     = "15.4"
  multi_az           = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `subnet_ids` | Private subnet IDs for the DB subnet group | `list(string)` | — | yes |
| `security_group_ids` | Security group IDs for DB access | `list(string)` | — | yes |
| `db_name` | Name of the initial database | `string` | — | yes |
| `username` | Master username | `string` | — | yes |
| `password` | Master password (use a secret) | `string` | — | yes |
| `instance_class` | RDS instance class | `string` | `"db.t3.micro"` | no |
| `engine` | Database engine (`postgres`, `mysql`) | `string` | `"postgres"` | no |
| `engine_version` | Engine version | `string` | `"15.4"` | no |
| `allocated_storage` | Storage in GB | `number` | `20` | no |
| `multi_az` | Enable Multi-AZ deployment | `bool` | `false` | no |
| `deletion_protection` | Prevent accidental deletion | `bool` | `true` | no |
| `skip_final_snapshot` | Skip final snapshot on destroy | `bool` | `false` | no |

## Outputs

| Name | Description |
|---|---|
| `endpoint` | Connection endpoint (host:port) |
| `port` | Database port |
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | ARN of the DB instance |
