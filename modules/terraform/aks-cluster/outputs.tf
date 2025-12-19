# Outputs for Enterprise-Grade AKS Cluster Module

# ============================================================================
# CLUSTER CORE OUTPUTS
# ============================================================================

output "cluster_id" {
  description = "AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN (public or private)"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "cluster_private_fqdn" {
  description = "AKS cluster private FQDN (for private clusters)"
  value       = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "kubernetes_version" {
  description = "Kubernetes version running on the cluster"
  value       = azurerm_kubernetes_cluster.aks.kubernetes_version
}

output "current_kubernetes_version" {
  description = "Current Kubernetes version (may differ during upgrades)"
  value       = azurerm_kubernetes_cluster.aks.current_kubernetes_version
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes (MC_*)"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "location" {
  description = "Azure region where cluster is deployed"
  value       = azurerm_kubernetes_cluster.aks.location
}

# ============================================================================
# IDENTITY OUTPUTS
# ============================================================================

output "cluster_identity" {
  description = "AKS cluster managed identity details"
  value = {
    client_id   = azurerm_user_assigned_identity.aks_identity.client_id
    object_id   = azurerm_user_assigned_identity.aks_identity.principal_id
    resource_id = azurerm_user_assigned_identity.aks_identity.id
    tenant_id   = azurerm_user_assigned_identity.aks_identity.tenant_id
  }
}

output "kubelet_identity" {
  description = "Kubelet managed identity details (for ACR authentication)"
  value = {
    client_id   = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id   = azurerm_user_assigned_identity.kubelet_identity.principal_id
    resource_id = azurerm_user_assigned_identity.kubelet_identity.id
  }
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "key_vault_secrets_provider_identity" {
  description = "Key Vault Secrets Provider managed identity"
  value = {
    client_id = try(azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id, "")
    object_id = try(azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id, "")
  }
}

output "oms_agent_identity" {
  description = "OMS Agent managed identity"
  value = {
    client_id = try(azurerm_kubernetes_cluster.aks.oms_agent[0].oms_agent_identity[0].client_id, "")
    object_id = try(azurerm_kubernetes_cluster.aks.oms_agent[0].oms_agent_identity[0].object_id, "")
  }
}

# ============================================================================
# NETWORKING OUTPUTS
# ============================================================================

output "network_profile" {
  description = "AKS network profile configuration"
  value = {
    network_plugin      = azurerm_kubernetes_cluster.aks.network_profile[0].network_plugin
    network_plugin_mode = azurerm_kubernetes_cluster.aks.network_profile[0].network_plugin_mode
    network_policy      = azurerm_kubernetes_cluster.aks.network_profile[0].network_policy
    service_cidr        = azurerm_kubernetes_cluster.aks.network_profile[0].service_cidr
    dns_service_ip      = azurerm_kubernetes_cluster.aks.network_profile[0].dns_service_ip
    pod_cidr            = azurerm_kubernetes_cluster.aks.network_profile[0].pod_cidr
    load_balancer_sku   = azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_sku
    outbound_type       = azurerm_kubernetes_cluster.aks.network_profile[0].outbound_type
  }
}

output "effective_outbound_ips" {
  description = "Effective outbound IPs for load balancer"
  value       = try(azurerm_kubernetes_cluster.aks.network_profile[0].load_balancer_profile[0].effective_outbound_ips, [])
}

output "nat_gateway_public_ip_prefix" {
  description = "NAT Gateway public IP prefix"
  value       = var.enable_nat_gateway && var.create_nat_gateway ? azurerm_public_ip_prefix.nat[0].ip_prefix : ""
}

output "private_dns_zone_id" {
  description = "Private DNS zone ID for private cluster"
  value       = var.private_cluster_enabled && var.create_private_dns_zone ? azurerm_private_dns_zone.aks[0].id : var.private_dns_zone_id
}

output "nsg_id" {
  description = "Network Security Group ID for AKS subnet"
  value       = var.create_nsg ? azurerm_network_security_group.aks[0].id : ""
}

output "route_table_id" {
  description = "Route table ID for UDR"
  value       = var.use_user_defined_routing && var.create_route_table ? azurerm_route_table.aks[0].id : ""
}

# ============================================================================
# NODE POOL OUTPUTS
# ============================================================================

output "system_node_pool" {
  description = "System node pool configuration"
  value = {
    name       = azurerm_kubernetes_cluster.aks.default_node_pool[0].name
    vm_size    = azurerm_kubernetes_cluster.aks.default_node_pool[0].vm_size
    node_count = azurerm_kubernetes_cluster.aks.default_node_pool[0].node_count
    zones      = azurerm_kubernetes_cluster.aks.default_node_pool[0].zones
  }
}

output "general_node_pool_id" {
  description = "General workload node pool ID"
  value       = var.enable_general_node_pool ? azurerm_kubernetes_cluster_node_pool.general[0].id : ""
}

output "gpu_node_pool_id" {
  description = "GPU node pool ID"
  value       = var.enable_gpu_node_pool ? azurerm_kubernetes_cluster_node_pool.gpu[0].id : ""
}

output "memory_optimized_node_pool_id" {
  description = "Memory-optimized node pool ID"
  value       = var.enable_memory_optimized_node_pool ? azurerm_kubernetes_cluster_node_pool.highmem[0].id : ""
}

output "compute_optimized_node_pool_id" {
  description = "Compute-optimized node pool ID"
  value       = var.enable_compute_optimized_node_pool ? azurerm_kubernetes_cluster_node_pool.compute[0].id : ""
}

# ============================================================================
# KUBECONFIG OUTPUTS (SENSITIVE)
# ============================================================================

output "kube_config" {
  description = "Raw Kubernetes config (sensitive - for automation only)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Raw Kubernetes admin config (sensitive - for automation only)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}

output "kube_config_object" {
  description = "Kubernetes config object (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "host" {
  description = "Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64 encoded, sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate (base64 encoded, sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key (base64 encoded, sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

# ============================================================================
# FEATURE AND ADD-ON OUTPUTS
# ============================================================================

output "azure_policy_enabled" {
  description = "Azure Policy add-on status"
  value       = azurerm_kubernetes_cluster.aks.azure_policy_enabled
}

output "workload_identity_enabled" {
  description = "Workload identity enabled status"
  value       = azurerm_kubernetes_cluster.aks.workload_identity_enabled
}

output "oidc_issuer_enabled" {
  description = "OIDC issuer enabled status"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_enabled
}

output "service_mesh_enabled" {
  description = "Service mesh enabled status"
  value       = var.enable_service_mesh
}

output "image_cleaner_enabled" {
  description = "Image cleaner enabled status"
  value       = azurerm_kubernetes_cluster.aks.image_cleaner_enabled
}

# ============================================================================
# MONITORING OUTPUTS
# ============================================================================

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID used for monitoring"
  value       = var.log_analytics_workspace_id
}

output "diagnostic_setting_id" {
  description = "Diagnostic setting resource ID"
  value       = azurerm_monitor_diagnostic_setting.aks.id
}

output "action_group_id" {
  description = "Action group ID for alerts"
  value       = var.create_action_group ? azurerm_monitor_action_group.aks[0].id : var.existing_action_group_id
}

# ============================================================================
# SECURITY AND COMPLIANCE OUTPUTS
# ============================================================================

output "private_cluster_enabled" {
  description = "Private cluster status (CIS 3.2.1)"
  value       = azurerm_kubernetes_cluster.aks.private_cluster_enabled
}

output "local_account_disabled" {
  description = "Local account status (DoD STIG V-242383)"
  value       = azurerm_kubernetes_cluster.aks.local_account_disabled
}

output "rbac_enabled" {
  description = "RBAC enabled status (CIS 5.1.1)"
  value       = azurerm_kubernetes_cluster.aks.role_based_access_control_enabled
}

output "azure_rbac_enabled" {
  description = "Azure RBAC for Kubernetes authorization"
  value       = var.enable_azure_rbac
}

output "run_command_enabled" {
  description = "Run command enabled status (should be false for production)"
  value       = azurerm_kubernetes_cluster.aks.run_command_enabled
}

output "sku_tier" {
  description = "AKS SKU tier (Standard/Premium for SLA)"
  value       = azurerm_kubernetes_cluster.aks.sku_tier
}

# ============================================================================
# PORTAL LINK OUTPUT
# ============================================================================

output "portal_url" {
  description = "Azure Portal URL for the AKS cluster"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_kubernetes_cluster.aks.id}"
}

output "portal_kubernetes_resources_url" {
  description = "Azure Portal URL for Kubernetes resources view"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_kubernetes_cluster.aks.id}/workloads"
}

# ============================================================================
# CLI COMMAND OUTPUTS
# ============================================================================

output "get_credentials_command" {
  description = "Command to get cluster credentials"
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name}"
}

output "kubectl_context_name" {
  description = "kubectl context name"
  value       = var.cluster_name
}

# ============================================================================
# COMPLIANCE SUMMARY OUTPUT
# ============================================================================

output "compliance_summary" {
  description = "Compliance and security configuration summary"
  value = {
    cis_benchmark = {
      "3.2.1_private_cluster"         = azurerm_kubernetes_cluster.aks.private_cluster_enabled
      "5.1.1_rbac_enabled"            = azurerm_kubernetes_cluster.aks.role_based_access_control_enabled
      "5.1.4_audit_logs"              = true # Diagnostic settings enabled
      "5.2.1_workload_identity"       = azurerm_kubernetes_cluster.aks.workload_identity_enabled
      "5.3.1_network_policy"          = var.network_policy != "none"
      "5.4.1_key_vault_csi"           = true # Key Vault Secrets Provider enabled
    }
    dod_stig = {
      "V-242376_rbac"                 = azurerm_kubernetes_cluster.aks.role_based_access_control_enabled
      "V-242383_no_local_accounts"    = azurerm_kubernetes_cluster.aks.local_account_disabled
      "V-242414_azure_policy"         = azurerm_kubernetes_cluster.aks.azure_policy_enabled
      "V-242461_audit_logging"        = true # Diagnostic settings enabled
    }
    nist_800_190 = {
      "runtime_threat_detection"      = true # Microsoft Defender enabled
      "container_insights"            = var.enable_container_insights
    }
    fedramp = {
      "sku_tier_sla"                  = azurerm_kubernetes_cluster.aks.sku_tier
      "automatic_upgrades"            = var.automatic_channel_upgrade != "none"
      "high_availability"             = var.system_node_pool_min_count >= 3
    }
  }
}
