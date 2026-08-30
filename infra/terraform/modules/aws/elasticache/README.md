# Module: aws/elasticache

Provisions an ElastiCache Redis replication group with a private subnet group and encryption in transit and at rest.

## Usage

```hcl
module "elasticache" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/elasticache?ref=v2.0.0"

  project_name       = "my-app"
  environment        = "prod"
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_group.security_group_id]
  node_type          = "cache.t3.micro"
  engine_version     = "7.0"
  num_cache_clusters = 2
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `subnet_ids` | Private subnet IDs for the cache subnet group | `list(string)` | — | yes |
| `security_group_ids` | Security group IDs for cluster access | `list(string)` | — | yes |
| `node_type` | ElastiCache node type | `string` | `"cache.t3.micro"` | no |
| `engine_version` | Redis engine version | `string` | `"7.0"` | no |
| `num_cache_clusters` | Number of cache nodes (1 = no HA) | `number` | `1` | no |
| `parameter_group_name` | Parameter group name (empty = default for engine) | `string` | `""` | no |
| `at_rest_encryption` | Enable at-rest encryption | `bool` | `true` | no |
| `transit_encryption` | Enable in-transit encryption (TLS) | `bool` | `true` | no |

## Outputs

| Name | Description |
|---|---|
| `primary_endpoint` | Primary endpoint address |
| `port` | Redis port (default 6379) |
| `replication_group_id` | ElastiCache replication group ID |
