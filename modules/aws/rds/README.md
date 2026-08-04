# Module: aws/rds

Creates an AWS RDS instance (PostgreSQL or MySQL) with storage encryption, enhanced monitoring, Performance Insights, automated backups, and deletion protection enabled by default.

## Usage

```hcl
module "rds" {
  source = "github.com/rafatusa/terraform-enterprise-modules//infra/modules/aws/rds?ref=v1.1.0"

  identifier     = "my-app-db"
  project        = "my-project"
  environment    = "production"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"

  db_name  = "appdb"
  username = "appuser"
  password = var.db_password   # pass via TF_VAR_db_password secret

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  app_security_group = module.ec2.security_group_id

  allocated_storage     = 20
  max_allocated_storage = 100
  backup_retention_days = 7
}
```

## Security Defaults

- `publicly_accessible = false`
- `storage_encrypted = true`
- `deletion_protection = true`
- Performance Insights and Enhanced Monitoring enabled

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| identifier | RDS instance identifier | `string` | — | yes |
| project | Project tag | `string` | — | yes |
| environment | Environment tag | `string` | `production` | no |
| engine | `postgres` or `mysql` | `string` | `postgres` | no |
| engine_version | Engine version | `string` | `15.4` | no |
| instance_class | Instance class | `string` | `db.t3.micro` | no |
| db_name | Initial database name | `string` | — | yes |
| username | Master username | `string` | — | yes |
| password | Master password (use secret) | `string` | — | yes |
| vpc_id | VPC ID | `string` | — | yes |
| subnet_ids | Private subnet IDs | `list(string)` | — | yes |
| app_security_group | App SG allowed to connect | `string` | — | yes |
| allocated_storage | Initial storage (GB) | `number` | `20` | no |
| max_allocated_storage | Max autoscale storage (GB) | `number` | `100` | no |
| backup_retention_days | Automated backup retention | `number` | `7` | no |
| tags | Additional tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `endpoint` | RDS connection endpoint |
| `port` | Database port |
| `db_name` | Database name |
| `security_group_id` | RDS security group ID |
