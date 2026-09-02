# Module: aws/eks

Creates an EKS cluster with a managed node group, including the IAM roles both require.

## Usage

```hcl
module "eks" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/terraform/modules/aws/eks?ref=v2.0.0"

  project_name = "my-app"
  environment  = "prod"

  subnet_ids         = module.vpc.private_subnet_ids
  kubernetes_version = "1.29"

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  desired_size = 3
  min_size     = 2
  max_size     = 6
}
```

## IAM roles are created for you

This module creates both the cluster role and the node group role, with the required AWS
managed policies attached:

- Cluster: `AmazonEKSClusterPolicy`
- Nodes: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`,
  `AmazonEC2ContainerRegistryReadOnly`

Do **not** compose `aws/iam-role` alongside this module expecting to supply them — there
is no input for an externally created role, and the extra role would be unused. The role
ARNs are exported as `cluster_role_arn` and `node_group_role_arn` if you need to attach
further policies.

## Subnets

`subnet_ids` must span **at least two availability zones**. The same list is used for
both the control plane ENIs and the node group. Private subnets are recommended; if you
use them, ensure a NAT gateway exists so nodes can reach the EKS API and ECR (the
`aws/vpc` module's `enable_nat_gateway` does this).

## Connecting

```bash
aws eks update-kubeconfig --name <cluster_name> --region <region>
```

`endpoint_public_access` defaults to `true`. Private access is always enabled as well.
Setting it to `false` means you can only reach the API server from inside the VPC.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_name` | Project name used for resource naming | `string` | — | yes |
| `environment` | Deployment environment | `string` | `"dev"` | no |
| `kubernetes_version` | Kubernetes control-plane version | `string` | `"1.29"` | no |
| `subnet_ids` | Subnet IDs for control plane and node group (2 or more AZs) | `list(string)` | `null` | no |
| `endpoint_public_access` | Allow public API server endpoint access | `bool` | `true` | no |
| `instance_types` | EC2 instance types for the managed node group | `list(string)` | `["t3.medium"]` | no |
| `capacity_type` | Node capacity type: `ON_DEMAND` or `SPOT` | `string` | `"ON_DEMAND"` | no |
| `desired_size` | Desired number of worker nodes | `number` | `2` | no |
| `min_size` | Minimum number of worker nodes | `number` | `1` | no |
| `max_size` | Maximum number of worker nodes | `number` | `4` | no |
| `tags` | Additional tags merged into every resource | `map(string)` | `{}` | no |

The variable is `instance_types` (plural list), not `node_instance_types`. There is no
`disk_size` input — nodes use the EKS-optimised AMI default.

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | EKS API server endpoint |
| `cluster_ca_certificate` | Base64-encoded cluster CA certificate (sensitive) |
| `cluster_role_arn` | ARN of the EKS cluster IAM role |
| `node_group_role_arn` | ARN of the EKS node group IAM role |

There is no `node_group_id` output.

## Notes

- Cluster name is `<project_name>-<environment>-cluster`; the node group is
  `<project_name>-<environment>-nodes`.
- `update_config.max_unavailable` is hardcoded to `1`, so node group upgrades roll one
  node at a time.
- The node group depends on all three policy attachments, so nodes never launch before
  they can join the cluster.
