# RBAC Role Assignments for AKS Cluster
# Implements least privilege access following CIS and DoD STIG requirements

# AKS Cluster Identity -> Network Contributor on AKS Subnet
# Required for load balancer and route management
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true
}

# AKS Cluster Identity -> Monitoring Metrics Publisher
# Required for metrics collection
resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true
}

# Kubelet Identity -> AcrPull on Container Registry
# Required for pulling images from Azure Container Registry
resource "azurerm_role_assignment" "kubelet_acr_pull" {
  count = var.container_registry_id != "" ? 1 : 0

  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id

  skip_service_principal_aad_check = true
}

# OMS Agent Identity -> Monitoring Metrics Publisher (if using separate identity)
resource "azurerm_role_assignment" "oms_monitoring_metrics" {
  count = var.enable_separate_oms_identity ? 1 : 0

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks.oms_agent[0].oms_agent_identity[0].object_id

  skip_service_principal_aad_check = true
}

# Key Vault Secrets User -> Key Vault (for CSI driver)
resource "azurerm_role_assignment" "keyvault_secrets_user" {
  count = var.key_vault_id != "" ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id

  skip_service_principal_aad_check = true
}

# Azure AD Group -> Azure Kubernetes Service Cluster Admin Role
# Cluster-level admin access via Azure RBAC
resource "azurerm_role_assignment" "aks_cluster_admin" {
  for_each = var.enable_azure_rbac ? toset(var.admin_group_object_ids) : []

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = each.value

  skip_service_principal_aad_check = true
}

# Azure AD Group -> Azure Kubernetes Service Cluster User Role
# Read-only access for platform viewers
resource "azurerm_role_assignment" "aks_cluster_user" {
  for_each = var.enable_azure_rbac ? toset(var.viewer_group_object_ids) : []

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = each.value

  skip_service_principal_aad_check = true
}

# Azure AD Group -> Azure Kubernetes Service RBAC Cluster Admin
# Full Kubernetes RBAC cluster-admin permissions
resource "azurerm_role_assignment" "aks_rbac_cluster_admin" {
  for_each = var.enable_azure_rbac && var.grant_kubernetes_cluster_admin ? toset(var.admin_group_object_ids) : []

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value

  skip_service_principal_aad_check = true
}

# Azure AD Group -> Azure Kubernetes Service RBAC Reader
# Read-only Kubernetes RBAC permissions
resource "azurerm_role_assignment" "aks_rbac_reader" {
  for_each = var.enable_azure_rbac ? toset(var.viewer_group_object_ids) : []

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = each.value

  skip_service_principal_aad_check = true
}

# Developer Group -> Azure Kubernetes Service RBAC Writer (namespace-scoped)
# Write permissions for specific namespaces
resource "azurerm_role_assignment" "aks_rbac_writer" {
  for_each = var.enable_azure_rbac && var.grant_developer_access ? toset(var.developer_group_object_ids) : []

  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = each.value

  skip_service_principal_aad_check = true
}

# Custom Role Definition for namespace-scoped access (if needed)
resource "azurerm_role_definition" "aks_namespace_admin" {
  count = var.create_custom_namespace_admin_role ? 1 : 0

  name        = "${var.cluster_name}-namespace-admin"
  scope       = azurerm_kubernetes_cluster.aks.id
  description = "Custom role for namespace-scoped admin access in AKS"

  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_kubernetes_cluster.aks.id
  ]
}

# Managed Identity Operator (if workload identity is enabled)
# Allows cluster to manage federated identities
resource "azurerm_role_assignment" "aks_managed_identity_operator" {
  count = var.enable_workload_identity_rbac ? 1 : 0

  scope                = var.resource_group_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true
}

# Virtual Machine Contributor (for VMSS operations)
# Required for node pool management
resource "azurerm_role_assignment" "aks_vm_contributor" {
  count = var.grant_vm_contributor_role ? 1 : 0

  scope                = var.node_resource_group_id != "" ? var.node_resource_group_id : "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${local.node_resource_group}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# Private DNS Zone Contributor (for private cluster DNS management)
resource "azurerm_role_assignment" "aks_private_dns_contributor" {
  count = var.private_cluster_enabled && var.grant_private_dns_contributor ? 1 : 0

  scope                = var.private_dns_zone_id != "" ? var.private_dns_zone_id : azurerm_private_dns_zone.aks[0].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id

  skip_service_principal_aad_check = true
}
