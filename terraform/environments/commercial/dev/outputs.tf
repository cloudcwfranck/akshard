output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks_cluster.cluster_name
}

output "cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks_cluster.cluster_id
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks_cluster.cluster_fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks_cluster.oidc_issuer_url
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.aks.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.networking.vnet_id
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${module.aks_cluster.cluster_name}"
}
