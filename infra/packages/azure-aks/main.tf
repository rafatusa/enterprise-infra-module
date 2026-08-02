###############################################################################
# Package: azure-aks
# Purpose: Complete production AKS environment — Resource Group, VNet, Subnets,
#          NSG, Managed Identity, Log Analytics, AKS Cluster.
#          Consumers reference: github.com/org/terraform-enterprise-modules//infra/packages/azure-aks?ref=v1.0.0
###############################################################################

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

###############################################################################
# Resource Group
###############################################################################
module "resource_group" {
  source = "../../modules/azure/resource-group"

  name        = var.resource_group_name
  location    = var.location
  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# Virtual Network + Subnets
###############################################################################
module "vnet" {
  source = "../../modules/azure/vnet"

  name                = "${var.cluster_name}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = [var.vnet_cidr]

  subnets = {
    "aks-system" = {
      address_prefixes  = [var.system_subnet_cidr]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
    "aks-user" = {
      address_prefixes  = [var.user_subnet_cidr]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
  }

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# Network Security Group — applied to AKS subnets
###############################################################################
module "nsg" {
  source = "../../modules/azure/nsg"

  name                = "${var.cluster_name}-nsg"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  security_rules = [
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all inbound traffic not explicitly allowed"
    }
  ]

  subnet_ids = [
    module.vnet.subnet_ids["aks-system"],
    module.vnet.subnet_ids["aks-user"],
  ]

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# Managed Identity — for AKS control plane
###############################################################################
module "managed_identity" {
  source = "../../modules/azure/managed-identity"

  name                = "${var.cluster_name}-identity"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  role_assignments = []

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# Log Analytics Workspace
###############################################################################
module "log_analytics" {
  source = "../../modules/azure/log-analytics"

  name                      = "${var.cluster_name}-logs"
  resource_group_name       = module.resource_group.name
  location                  = module.resource_group.location
  retention_in_days         = var.log_retention_days
  enable_container_insights = true

  project     = var.project
  environment = var.environment
  tags        = var.tags
}

###############################################################################
# AKS Cluster
###############################################################################
module "aks" {
  source = "../../modules/azure/aks"

  cluster_name              = var.cluster_name
  resource_group_name       = module.resource_group.name
  location                  = module.resource_group.location
  kubernetes_version        = var.kubernetes_version
  user_assigned_identity_id = module.managed_identity.id
  subnet_id                 = module.vnet.subnet_ids["aks-system"]
  log_analytics_workspace_id = module.log_analytics.id

  private_cluster_enabled   = var.private_cluster_enabled
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_rbac_enabled        = true
  admin_group_object_ids    = var.admin_group_object_ids

  system_vm_size            = var.system_vm_size
  system_node_count         = var.system_node_count
  system_min_count          = var.system_min_count
  system_max_count          = var.system_max_count
  system_enable_autoscaling = true
  availability_zones        = var.availability_zones

  user_node_pools = var.user_node_pools

  project     = var.project
  environment = var.environment
  tags        = var.tags
}
