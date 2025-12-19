# Networking Resources for AKS Cluster
# NSG, Route Tables, NAT Gateway, Private DNS Zone

# Network Security Group for AKS Subnet
resource "azurerm_network_security_group" "aks" {
  count = var.create_nsg ? 1 : 0

  name                = "${var.cluster_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # CIS 5.3.2 - Ensure network security groups are configured

  # Allow inbound from Azure Load Balancer health probes
  security_rule {
    name                       = "Allow-AzureLoadBalancer-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Allow inbound from Application Gateway (if used)
  dynamic "security_rule" {
    for_each = var.allow_application_gateway ? [1] : []
    content {
      name                       = "Allow-AppGateway-Inbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["80", "443"]
      source_address_prefixes    = var.application_gateway_subnet_cidrs
      destination_address_prefix = "*"
    }
  }

  # Allow outbound to Azure services (for AKS control plane, ACR, etc.)
  security_rule {
    name                       = "Allow-AzureCloud-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "9000"]
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Allow outbound NTP
  security_rule {
    name                       = "Allow-NTP-Outbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "123"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound DNS
  security_rule {
    name                       = "Allow-DNS-Outbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny all inbound by default
  security_rule {
    name                       = "Deny-All-Inbound"
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

# NSG Association
resource "azurerm_subnet_network_security_group_association" "aks" {
  count = var.create_nsg && var.associate_nsg_to_subnet ? 1 : 0

  subnet_id                 = var.aks_subnet_id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}

# Route Table (User Defined Routing)
resource "azurerm_route_table" "aks" {
  count = var.use_user_defined_routing && var.create_route_table ? 1 : 0

  name                          = "${var.cluster_name}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  # Default route to Azure Firewall or NAT Gateway
  dynamic "route" {
    for_each = var.default_route_next_hop_ip != "" ? [1] : []
    content {
      name                   = "DefaultRoute"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.default_route_next_hop_ip
    }
  }

  # Route to Azure services (optional, for performance)
  dynamic "route" {
    for_each = var.create_azure_service_routes ? var.azure_service_routes : {}
    content {
      name           = route.key
      address_prefix = route.value.address_prefix
      next_hop_type  = route.value.next_hop_type
    }
  }

  tags = local.default_tags
}

# Route Table Association
resource "azurerm_subnet_route_table_association" "aks" {
  count = var.use_user_defined_routing && var.create_route_table && var.associate_route_table_to_subnet ? 1 : 0

  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.aks[0].id
}

# NAT Gateway Public IP Prefix (for consistent egress IPs)
resource "azurerm_public_ip_prefix" "nat" {
  count = var.enable_nat_gateway && var.create_nat_gateway ? 1 : 0

  name                = "${var.cluster_name}-nat-pip-prefix"
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix_length       = var.nat_gateway_public_ip_prefix_length
  zones               = var.nat_gateway_zones

  tags = local.default_tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "aks" {
  count = var.enable_nat_gateway && var.create_nat_gateway ? 1 : 0

  name                    = "${var.cluster_name}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_minutes
  zones                   = var.nat_gateway_zones

  tags = local.default_tags
}

# NAT Gateway - Public IP Prefix Association
resource "azurerm_nat_gateway_public_ip_prefix_association" "nat" {
  count = var.enable_nat_gateway && var.create_nat_gateway ? 1 : 0

  nat_gateway_id      = azurerm_nat_gateway.aks[0].id
  public_ip_prefix_id = azurerm_public_ip_prefix.nat[0].id
}

# NAT Gateway - Subnet Association
resource "azurerm_subnet_nat_gateway_association" "aks" {
  count = var.enable_nat_gateway && var.create_nat_gateway && var.associate_nat_gateway_to_subnet ? 1 : 0

  subnet_id      = var.aks_subnet_id
  nat_gateway_id = azurerm_nat_gateway.aks[0].id
}

# Private DNS Zone for Private Cluster
resource "azurerm_private_dns_zone" "aks" {
  count = var.private_cluster_enabled && var.create_private_dns_zone ? 1 : 0

  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name

  tags = local.default_tags
}

# Private DNS Zone - VNet Link (cluster VNet)
resource "azurerm_private_dns_zone_virtual_network_link" "aks_cluster_vnet" {
  count = var.private_cluster_enabled && var.create_private_dns_zone ? 1 : 0

  name                  = "${var.cluster_name}-cluster-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.default_tags
}

# Private DNS Zone - VNet Link (hub VNet for hybrid connectivity)
resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub_vnet" {
  count = var.private_cluster_enabled && var.create_private_dns_zone && var.link_to_hub_vnet ? 1 : 0

  name                  = "${var.cluster_name}-hub-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = var.hub_vnet_id
  registration_enabled  = false

  tags = local.default_tags
}

# DDoS Protection Plan (optional, for production)
resource "azurerm_network_ddos_protection_plan" "aks" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.cluster_name}-ddos"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.default_tags
}
