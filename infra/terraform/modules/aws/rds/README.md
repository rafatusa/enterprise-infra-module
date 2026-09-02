# Module: aws/rds

Provisions an RDS database instance inside a private DB subnet group, together with
a dedicated security group that allows the database port from the security groups you
nominate. Storage is encrypted and autoscaling, and the instance is never publicly
accessible.

## Usage

```hcl
module "rds" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/rds?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Security groups permitted to reach the DB port.
  allowed_security_group_ids = [module.app_sg.security_group_id]

  db_name  = "appdb"
  username = "appuser"
  password = var.db_password

  engine         = "postgres"
  engine_version = "15.4"
  family         = "postgres15"
  instance_class = "db.t3.micro"

  # Production-safe overrides — see the note below.
  multi_az            = true
  deletion_protection = true
  skip_final_snapshot = false
}
```

> **Production defaults are NOT safe by default.** `deletion_protection` defaults to
> `false` and `skip_final_snapshot` defaults to `true`, which favours easy teardown of
> throwaway environments. For any database holding real data you **must** set
> `deletion_protection = true` and `skip_final_snapshot = false` explicitly, as shown
> above. Leaving the defaults means the instance can be destroyed by a `terraform
> destroy` with no final snapshot taken.

## Network wiring

This module creates its own security group. You do not pass one in. Instead:

- `vpc_id` — the VPC the security group is created in.
- `allowed_security_group_ids` — the source security groups allowed on `port`.

The resulting group is exported as `db_security_group_id` if you need to reference it.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `engine` | Database engine (`postgres`, `mysql`, `mariadb`, ...) | `string` | `"postgres"` | no |
| `engine_version` | Engine version | `string` | `"15.4"` | no |
| `family` | DB parameter group family (e.g. `postgres15`) | `string` | `"postgres15"` | no |
| `instance_class` | RDS instance class | `string` | `"db.t3.micro"` | no |
| `db_name` | Name of the initial database to create | `string` | `null` | no |
| `username` | Master DB username | `string` | `null` | no |
| `password` | Master DB password (sensitive — pass a secret) | `string` | `null` | no |
| `port` | Database port | `number` | `5432` | no |
| `allocated_storage` | Initial allocated storage in GiB | `number` | `20` | no |
| `max_allocated_storage` | Upper limit for storage autoscaling in GiB | `number` | `100` | no |
| `multi_az` | Enable Multi-AZ deployment for HA | `bool` | `false` | no |
| `subnet_ids` | Subnet IDs for the DB subnet group (Multi-AZ needs 2 or more) | `list(string)` | `null` | no |
| `vpc_id` | VPC ID for the RDS security group | `string` | `null` | no |
| `allowed_security_group_ids` | Security group IDs that may connect to the DB | `list(string)` | `[]` | no |
| `backup_retention_period` | Automated backup retention in days (`0` disables) | `number` | `7` | no |
| `skip_final_snapshot` | Skip final snapshot on destroy (set `false` for production) | `bool` | `true` | no |
| `deletion_protection` | Prevent accidental deletion via API/console | `bool` | `false` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

Although `db_name`, `username`, `password`, `subnet_ids` and `vpc_id` are declared with
a `null` default so the module can be planned in isolation, RDS will not create a usable
instance without them. Treat them as effectively required.

## Outputs

| Name | Description |
|---|---|
| `db_instance_id` | RDS instance identifier |
| `db_instance_arn` | RDS instance ARN |
| `db_endpoint` | RDS connection endpoint (`host:port`) |
| `db_address` | RDS hostname |
| `db_port` | RDS port |
| `db_security_group_id` | ID of the security group created for the DB |

## Notes

- Storage is always encrypted (`storage_encrypted = true`) and uses `gp3`.
- `publicly_accessible` is hardcoded to `false`; expose the database through your VPC,
  never directly.
- Backup window is `03:00-04:00` UTC and maintenance `Mon:04:00-Mon:05:00` UTC.
- The parameter group uses `create_before_destroy` so `family` changes do not deadlock.
