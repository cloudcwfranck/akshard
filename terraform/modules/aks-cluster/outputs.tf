# Outputs for AKS Cluster Module

output "cluster_id" {
  description = "AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "cluster_private_fqdn" {
  description = "AKS cluster private FQDN"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Kubernetes admin configuration"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value = {
    client_id   = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id   = azurerm_user_assigned_identity.kubelet_identity.principal_id
    resource_id = azurerm_user_assigned_identity.kubelet_identity.id
  }
}

output "cluster_identity" {
  description = "AKS cluster managed identity"
  value = {
    client_id   = azurerm_user_assigned_identity.aks_identity.client_id
    object_id   = azurerm_user_assigned_identity.aks_identity.principal_id
    resource_id = azurerm_user_assigned_identity.aks_identity.id
  }
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "effective_outbound_ips" {
  description = "Effective outbound IPs for load balancer"
  value       = azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips
}

output "key_vault_secrets_provider" {
  description = "Key Vault Secrets Provider configuration"
  value = {
    enabled   = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_rotation_enabled
    client_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
    object_id = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
  }
}

output "kubernetes_version" {
  description = "Kubernetes version running on the cluster"
  value       = azurerm_kubernetes_cluster.aks.kubernetes_version
}

output "current_kubernetes_version" {
  description = "Current Kubernetes version"
  value       = azurerm_kubernetes_cluster.aks.current_kubernetes_version
}
