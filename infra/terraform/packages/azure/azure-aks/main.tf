/**
 * Package: azure-aks
 *
 * Opinionated AKS platform composed from this repository's Azure modules:
 * resource-group + vnet + nsg + managed-identity + log-analytics + aks.
 *
 * Terraform equivalent of infra/pulumi/packages/azure/azure-aks.
 *
 * This is a reusable composition, not a deployable root module: it declares
 * no backend and no provider. The consuming root module owns both.
 */

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Package     = "azure-aks"
      ManagedBy   = "Terraform"
    },
    var.tags,
  )

  # vnet exposes subnet_ids as a map keyed by subnet name, so the node subnet
  # is selected by name rather than by position.
  node_subnet_id = module.vnet.subnet_ids[var.node_subnet_name]
}

module "resource_group" {
  source = "../../../modules/azure/resource-group"

  project_name = var.project_name
  environment  = var.environment
  name         = var.resource_group_suffix
  location     = var.location
  tags         = local.common_tags
}

module "vnet" {
  source = "../../../modules/azure/vnet"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  address_space       = var.address_space
  subnets             = var.subnets
  tags                = local.common_tags
}

module "nsg" {
  source = "../../../modules/azure/nsg"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  subnet_ids          = [local.node_subnet_id]
  security_rules      = var.security_rules
  tags                = local.common_tags
}

module "identity" {
  source = "../../../modules/azure/managed-identity"

  project_name        = var.project_name
  environment         = var.environment
  identity_name       = "aks"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  tags                = local.common_tags
}

module "log_analytics" {
  source = "../../../modules/azure/log-analytics"

  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_in_days
  tags                = local.common_tags
}

module "aks" {
  source = "../../../modules/azure/aks"

  project_name               = var.project_name
  environment                = var.environment
  resource_group_name        = module.resource_group.resource_group_name
  location                   = module.resource_group.location
  subnet_id                  = local.node_subnet_id
  kubernetes_version         = var.kubernetes_version
  system_node_count          = var.system_node_count
  system_node_vm_size        = var.system_node_vm_size
  enable_auto_scaling        = var.enable_auto_scaling
  min_node_count             = var.min_node_count
  max_node_count             = var.max_node_count
  user_node_pools            = var.user_node_pools
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = local.common_tags
}
