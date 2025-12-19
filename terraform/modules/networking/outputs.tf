output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "vnet_name" {
  description = "Virtual Network name"
  value       = azurerm_virtual_network.aks_vnet.name
}

output "aks_subnet_id" {
  description = "AKS nodes subnet ID"
  value       = azurerm_subnet.aks_nodes.id
}

output "aks_subnet_name" {
  description = "AKS nodes subnet name"
  value       = azurerm_subnet.aks_nodes.name
}

output "api_subnet_id" {
  description = "API server subnet ID"
  value       = var.enable_api_server_vnet_integration ? azurerm_subnet.api_server[0].id : null
}

output "app_gateway_subnet_id" {
  description = "Application Gateway subnet ID"
  value       = var.enable_application_gateway ? azurerm_subnet.app_gateway[0].id : null
}

output "private_endpoints_subnet_id" {
  description = "Private endpoints subnet ID"
  value       = var.enable_private_endpoints ? azurerm_subnet.private_endpoints[0].id : null
}

output "bastion_subnet_id" {
  description = "Bastion subnet ID"
  value       = var.enable_bastion ? azurerm_subnet.bastion[0].id : null
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.aks[0].id : null
}

output "nat_gateway_public_ip_prefix" {
  description = "NAT Gateway public IP prefix"
  value       = var.enable_nat_gateway ? azurerm_public_ip_prefix.nat[0].ip_prefix : null
}

output "aks_nsg_id" {
  description = "AKS nodes NSG ID"
  value       = azurerm_network_security_group.aks_nodes.id
}
