# Networking Module for AKS
# Implements network security best practices and microsegmentation

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
  }
}

locals {
  default_tags = merge(
    var.tags,
    {
      "ManagedBy" = "Terraform"
      "Module"    = "networking"
    }
  )
}

# Virtual Network
resource "azurerm_virtual_network" "aks_vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = local.default_tags
}

# AKS Node Subnet
resource "azurerm_subnet" "aks_nodes" {
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.aks_subnet_address_prefixes

  # Delegate to AKS
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
    "Microsoft.Sql"
  ]
}

# API Server VNet Integration Subnet (for private clusters)
resource "azurerm_subnet" "api_server" {
  count = var.enable_api_server_vnet_integration ? 1 : 0

  name                 = var.api_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.api_subnet_address_prefixes

  delegation {
    name = "aks-delegation"

    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Application Gateway Subnet (for AGIC)
resource "azurerm_subnet" "app_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  name                 = var.appgw_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.appgw_subnet_address_prefixes

  service_endpoints = []
}

# Azure Bastion Subnet (for secure management access)
resource "azurerm_subnet" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                 = "AzureBastionSubnet" # Name must be exactly this
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.bastion_subnet_address_prefixes
}

# Private Endpoints Subnet
resource "azurerm_subnet" "private_endpoints" {
  count = var.enable_private_endpoints ? 1 : 0

  name                 = var.private_endpoints_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.private_endpoints_subnet_address_prefixes

  private_endpoint_network_policies_enabled = false
}

# Network Security Group for AKS Nodes
# CIS 5.3.2 - Ensure network policies are in place
resource "azurerm_network_security_group" "aks_nodes" {
  name                = "${var.aks_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Outbound rules for AKS requirements
  security_rule {
    name                       = "Allow_AKS_Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "9000"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "Allow_NTP"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny all other inbound by default
  security_rule {
    name                       = "Deny_All_Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.default_tags
}

# NSG Association for AKS Nodes Subnet
resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}

# Network Security Group for Application Gateway
resource "azurerm_network_security_group" "app_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  name                = "${var.appgw_subnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Application Gateway required rules
  security_rule {
    name                       = "Allow_GatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.default_tags
}

# NSG Association for App Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "app_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  subnet_id                 = azurerm_subnet.app_gateway[0].id
  network_security_group_id = azurerm_network_security_group.app_gateway[0].id
}

# Route Table for AKS (if custom routing needed)
resource "azurerm_route_table" "aks" {
  count = var.enable_custom_route_table ? 1 : 0

  name                          = "${var.aks_subnet_name}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false

  tags = local.default_tags
}

# Route Table Association
resource "azurerm_subnet_route_table_association" "aks" {
  count = var.enable_custom_route_table ? 1 : 0

  subnet_id      = azurerm_subnet.aks_nodes.id
  route_table_id = azurerm_route_table.aks[0].id
}

# NAT Gateway for secure outbound (optional, better than load balancer)
resource "azurerm_public_ip_prefix" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${var.vnet_name}-nat-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = 30 # 4 IP addresses
  zones               = var.nat_gateway_zones

  tags = local.default_tags
}

resource "azurerm_nat_gateway" "aks" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "${var.vnet_name}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = var.nat_gateway_zones

  tags = local.default_tags
}

resource "azurerm_nat_gateway_public_ip_prefix_association" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.aks[0].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = azurerm_subnet.aks_nodes.id
  nat_gateway_id = azurerm_nat_gateway.aks[0].id
}

# DDoS Protection Plan (for production environments)
resource "azurerm_network_ddos_protection_plan" "aks" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.vnet_name}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.default_tags
}
