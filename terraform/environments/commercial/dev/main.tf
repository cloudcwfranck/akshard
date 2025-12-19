# Example AKS Development Environment - Azure Commercial Cloud
# This is a reference implementation for deploying a hardened AKS cluster

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  # Configure remote state (customize for your environment)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "sttfstate"
  #   container_name       = "tfstate"
  #   key                  = "aks-dev.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# Data sources
data "azurerm_client_config" "current" {}

data "azuread_group" "aks_admins" {
  display_name     = var.aks_admin_group_name
  security_enabled = true
}

# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../../modules/networking"

  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  vnet_name           = "${var.cluster_name}-vnet"

  vnet_address_space            = ["10.0.0.0/16"]
  aks_subnet_address_prefixes   = ["10.0.0.0/20"]   # 4096 IPs for nodes
  api_subnet_address_prefixes   = ["10.0.16.0/28"]  # 16 IPs for API server

  enable_api_server_vnet_integration = true
  enable_nat_gateway                 = false # Using load balancer for dev
  enable_private_endpoints           = true
  enable_bastion                     = false
  enable_application_gateway         = false

  tags = local.common_tags
}

# AKS Cluster Module
module "aks_cluster" {
  source = "../../../modules/aks-cluster"

  cluster_name        = var.cluster_name
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  environment         = "dev"
  kubernetes_version  = var.kubernetes_version

  # Networking
  subnet_id    = module.networking.aks_subnet_id
  api_subnet_id = module.networking.api_subnet_id

  network_profile = {
    dns_service_ip    = "10.240.0.10"
    service_cidr      = "10.240.0.0/16"
    pod_cidr          = "10.244.0.0/16"
    outbound_type     = "loadBalancer"
    outbound_ip_count = 2
  }

  # Security
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  vnet_integration_enabled            = true
  disable_local_accounts              = true
  api_server_authorized_ip_ranges     = var.api_server_authorized_ip_ranges

  # SKU
  sku_tier = "Standard"

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  # Azure AD
  tenant_id              = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids = [data.azuread_group.aks_admins.object_id]

  # System node pool
  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    os_sku              = "AzureLinux"
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6
    node_count          = 3
    max_pods            = 30
    os_disk_size_gb     = 100
  }

  # Workload node pools
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D8s_v5"
      os_sku              = "AzureLinux"
      zones               = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 10
      node_count          = 2
      max_pods            = 50
      os_disk_size_gb     = 150
      node_labels = {
        workload = "general"
      }
      node_taints     = []
      priority        = "Regular"
      eviction_policy = "Delete"
      spot_max_price  = -1
    }
  }

  tags = local.common_tags
}

# Local variables
locals {
  common_tags = {
    Environment       = "Development"
    ManagedBy         = "Terraform"
    Project           = "AKS-Bootstrap-Kit"
    CostCenter        = "Engineering"
    SecurityBaseline  = "CIS-v1.8-DoD-STIG-v1r12"
    ComplianceLevel   = "FedRAMP-Moderate"
  }
}
