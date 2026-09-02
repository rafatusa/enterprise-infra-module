# Module: aws/elasticache

Creates a Redis replication group in a private subnet group, with encryption in transit
and at rest always enabled, and a dedicated security group.

## Usage

```hcl
module "cache" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/elasticache?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Security groups permitted to reach the Redis port.
  allowed_security_group_ids = [module.app_sg.security_group_id]

  node_type          = "cache.t3.small"
  num_cache_clusters = 2   # 2 or more enables automatic failover
}
```

## Encryption is mandatory

Both `at_rest_encryption_enabled` and `transit_encryption_enabled` are hardcoded to
`true` and cannot be disabled.

**Transit encryption means your client must speak TLS.** Connect with `rediss://` (two
s's), not `redis://`. A plaintext client will fail to connect, which is easy to mistake
for a networking problem.

Note that no auth token is configured, so access control is entirely by security group.

## Network wiring

This module creates its own security group. You do not pass one in:

- `vpc_id` — the VPC the security group is created in.
- `allowed_security_group_ids` — the source security groups allowed on `port`.

The resulting group is exported as `cache_security_group_id`.

## High availability

`num_cache_clusters` defaults to `1`, which is a single node with **no failover**.
Setting it to `2` or more enables `automatic_failover_enabled` and gives you a reader
endpoint with real replicas. Use at least `2` for anything holding state you care about,
and make sure `subnet_ids` spans multiple AZs.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `subnet_ids` | Subnet IDs for the ElastiCache subnet group | `list(string)` | `null` | no |
| `vpc_id` | VPC ID for the cache security group | `string` | `null` | no |
| `allowed_security_group_ids` | Security group IDs allowed to connect to the cache | `list(string)` | `[]` | no |
| `node_type` | ElastiCache node type | `string` | `"cache.t3.micro"` | no |
| `num_cache_clusters` | Number of cache clusters (2 or more enables automatic failover) | `number` | `1` | no |
| `port` | Redis port | `number` | `6379` | no |
| `parameter_group_name` | ElastiCache parameter group name | `string` | `"default.redis7"` | no |
| `engine_version` | Redis engine version | `string` | `"7.0"` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

Although `subnet_ids` and `vpc_id` default to `null` so the module can be planned in
isolation, the replication group cannot be created without them.

## Outputs

| Name | Description |
|---|---|
| `replication_group_id` | ElastiCache replication group ID |
| `primary_endpoint_address` | Primary endpoint address for read/write |
| `reader_endpoint_address` | Reader endpoint address for read replicas |
| `cache_security_group_id` | ID of the security group created for the cache |

`reader_endpoint_address` is only meaningful when `num_cache_clusters` is 2 or more.

## Notes

- The default `parameter_group_name` is `default.redis7`, an AWS-managed group. Some
  linters flag the use of a default parameter group; that is intentional here so the
  module works without the consumer creating one. Pass your own to override.
- `engine_version` and `parameter_group_name` must be compatible — a `7.x` engine needs
  a `redis7` family group.
