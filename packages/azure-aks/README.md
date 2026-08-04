# azure-aks package

A solution package that composes all 6 Azure modules into a complete, production-ready AKS environment in the correct dependency order.

## What it provisions

| Module | Resource |
|--------|----------|
| `azure/resource-group` | Resource Group (with delete lock) |
| `azure/log-analytics` | Log Analytics Workspace + Container Insights |
| `azure/vnet` | VNet, node subnet, pod subnet |
| `azure/nsg` | NSG for node subnet |
| `azure/managed-identity` | User-assigned Managed Identity for AKS |
| `azure/aks` | AKS cluster (private, AAD RBAC, Workload Identity) |

## Usage

```hcl
module "aks_env" {
  source = "github.com/rafatusa/enterprise-infra-module//infra/packages/azure-aks?ref=v1.1.0"

  cluster_name        = var.cluster_name
  resource_group_name = "${var.cluster_name}-rg"
  location            = var.location
  environment         = "production"

  admin_group_object_ids = ["<aad-admin-group-object-id>"]

  tags = {
    Project     = var.cluster_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

output "cluster_name"         { value = module.aks_env.cluster_name }
output "resource_group_name"  { value = module.aks_env.resource_group_name }
```

## GitHub Actions pipeline

```yaml
- uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: "1.7.0"

- name: Terraform init
  run: |
    terraform init -input=false -reconfigure \
      -backend-config="bucket=${{ secrets.TF_STATE_BUCKET }}" \
      -backend-config="key=${{ secrets.PROJECT_NAME }}/terraform.tfstate" \
      -backend-config="region=westeurope"
  working-directory: infra/

- name: Terraform apply
  run: terraform apply -auto-approve -input=false
  working-directory: infra/
  env:
    ARM_CLIENT_ID:       ${{ secrets.AZURE_CLIENT_ID }}
    ARM_CLIENT_SECRET:   ${{ secrets.AZURE_CLIENT_SECRET }}
    ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    ARM_TENANT_ID:       ${{ secrets.AZURE_TENANT_ID }}
    TF_VAR_cluster_name: ${{ secrets.PROJECT_NAME }}
    TF_VAR_location:     westeurope
```

## Key outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | AKS cluster name |
| `cluster_id` | AKS resource ID |
| `resource_group_name` | Resource group name |
| `oidc_issuer_url` | OIDC issuer URL for Workload Identity |
| `kube_config_raw` | Raw kubeconfig (sensitive) |
| `workspace_id` | Log Analytics workspace ID |
