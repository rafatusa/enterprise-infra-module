# Module: aws/eks

Provisions an EKS cluster with a managed node group and the required IAM roles for both the control plane and worker nodes.

## Usage

```hcl
module "eks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/eks?ref=v2.0.0"

  project_name        = "my-app"
  environment         = "prod"
  subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types = ["t3.medium"]
  desired_size        = 2
  min_size            = 1
  max_size            = 4
  kubernetes_version  = "1.29"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used in resource naming and tags | `string` | — | yes |
| `environment` | Deployment environment | `string` | — | yes |
| `subnet_ids` | Subnet IDs for the EKS cluster and node group | `list(string)` | — | yes |
| `kubernetes_version` | Kubernetes version for the cluster | `string` | `"1.29"` | no |
| `node_instance_types` | EC2 instance types for worker nodes | `list(string)` | `["t3.medium"]` | no |
| `desired_size` | Desired number of worker nodes | `number` | `2` | no |
| `min_size` | Minimum number of worker nodes | `number` | `1` | no |
| `max_size` | Maximum number of worker nodes | `number` | `4` | no |
| `disk_size` | Worker node EBS disk size in GB | `number` | `20` | no |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | API server endpoint |
| `cluster_ca_certificate` | Base64-encoded cluster CA certificate |
| `node_group_id` | Managed node group ID |
| `cluster_arn` | ARN of the EKS cluster |
