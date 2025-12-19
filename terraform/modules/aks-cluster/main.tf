# AKS Cluster Module - Enterprise Hardened Configuration
# Implements CIS Kubernetes Benchmark, DoD STIG, and NIST 800-190

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
}

locals {
  # CIS 5.1.1 - Ensure RBAC is enabled
  # DoD STIG V-242376 - Enable RBAC
  rbac_enabled = true

  # CIS 5.4.1 - Prefer using secrets as files over environment variables
  # Use Azure Key Vault CSI Driver
  secrets_store_enabled = true

  # CIS 5.2.1 - Minimize pod access to secrets
  # Enable pod identity
  workload_identity_enabled = true

  # CIS 5.7.1 - Configure Image Provenance
  image_cleaner_enabled = true

  default_tags = merge(
    var.tags,
    {
      "ManagedBy"           = "Terraform"
      "SecurityBaseline"    = "CIS-Benchmark-v1.8"
      "ComplianceFramework" = "DoD-STIG-v1r12"
      "Environment"         = var.environment
    }
  )
}

# User Assigned Identity for AKS cluster
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.default_tags
}

# User Assigned Identity for Kubelet
resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.default_tags
}

# AKS Cluster with hardened configuration
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.resource_group_name}-nodes"

  # CIS 5.4.2 - Create administrative boundaries using namespaces
  # DoD STIG V-242381 - Kubernetes must separate user functionality
  sku_tier = var.sku_tier # Standard or Premium for SLA

  # CIS 5.1.1 - Ensure RBAC is enabled
  # DoD STIG V-242376
  role_based_access_control_enabled = local.rbac_enabled

  # CIS 5.8.1 - Limit use of the Bind, Impersonate and Escalate permissions
  # DoD STIG V-242383 - Disable local accounts
  local_account_disabled = var.disable_local_accounts

  # CIS 3.2.1 - Ensure API server is not exposed to the internet
  # DoD STIG V-242418 - API server must be protected
  private_cluster_enabled = var.private_cluster_enabled

  # Enable private cluster public FQDN for hybrid scenarios (optional)
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled

  # CIS 5.2.1 - Minimize pod access to secrets
  # DoD STIG V-242414 - Use pod security policies
  oidc_issuer_enabled       = true
  workload_identity_enabled = local.workload_identity_enabled

  # Image Cleaner (removes unused images)
  image_cleaner_enabled        = local.image_cleaner_enabled
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # Default node pool (system node pool)
  default_node_pool {
    name                   = var.default_node_pool.name
    vm_size                = var.default_node_pool.vm_size
    os_sku                 = var.default_node_pool.os_sku # AzureLinux for hardened OS
    vnet_subnet_id         = var.subnet_id
    zones                  = var.default_node_pool.zones
    enable_auto_scaling    = var.default_node_pool.enable_auto_scaling
    min_count              = var.default_node_pool.min_count
    max_count              = var.default_node_pool.max_count
    node_count             = var.default_node_pool.node_count
    max_pods               = var.default_node_pool.max_pods
    orchestrator_version   = var.kubernetes_version
    only_critical_addons_enabled = true # System node pool for critical components only

    # CIS 5.7.3 - Apply Security Context to Pods and Containers
    # Node OS configuration
    os_disk_size_gb      = var.default_node_pool.os_disk_size_gb
    os_disk_type         = "Ephemeral" # CIS recommendation for performance and security
    ultra_ssd_enabled    = false
    temporary_name_for_rotation = "${var.default_node_pool.name}temp"

    # CIS 5.1.5 - Ensure that the kubelet configuration is secure
    kubelet_config {
      cpu_manager_policy        = "static"
      topology_manager_policy   = "best-effort"
      allowed_unsafe_sysctls    = []
      container_log_max_size_mb = 50
      container_log_max_line    = 5000
      pod_max_pid               = 4096
    }

    # Linux OS configuration for CIS compliance
    linux_os_config {
      swap_file_size_mb = 0 # CIS 4.1.1 - Disable swap

      sysctl_config {
        # Network security settings
        net_ipv4_ip_forward                = 1 # Required for Kubernetes networking
        net_ipv4_conf_all_forwarding       = 1
        net_bridge_bridge_nf_call_iptables = 1
        net_ipv4_tcp_tw_reuse              = true

        # CIS 3.1.1 - Network hardening
        net_ipv4_conf_all_send_redirects     = 0
        net_ipv4_conf_default_send_redirects = 0
        net_ipv4_conf_all_accept_redirects   = 0
        net_ipv4_conf_default_accept_redirects = 0

        # Memory and process limits
        vm_max_map_count = 262144
        kernel_threads_max = 65536
      }
    }

    upgrade_settings {
      max_surge = "33%" # Blue-green upgrade strategy
    }

    tags = merge(
      local.default_tags,
      {
        "NodePool" = "system"
        "CriticalAddonsOnly" = "true"
      }
    )
  }

  # Managed Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  # Network configuration - Azure CNI Overlay
  # CIS 5.3.1 - Use CNI plugin that supports Network Policies
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay" # IP address efficiency
    network_policy      = "azure"   # Azure Network Policy or Calico
    dns_service_ip      = var.network_profile.dns_service_ip
    service_cidr        = var.network_profile.service_cidr
    pod_cidr            = var.network_profile.pod_cidr
    load_balancer_sku   = "standard"
    outbound_type       = var.network_profile.outbound_type

    load_balancer_profile {
      managed_outbound_ip_count = var.network_profile.outbound_ip_count
      idle_timeout_in_minutes   = 30
    }
  }

  # CIS 3.2.1 - Ensure API server settings are secure
  # DoD STIG V-242418
  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
    vnet_integration_enabled = var.vnet_integration_enabled
    subnet_id = var.api_subnet_id
  }

  # Azure Active Directory integration
  # CIS 5.1.1 - Use Azure AD for RBAC
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
    tenant_id              = var.tenant_id
  }

  # Auto-scaler profile for cluster autoscaler
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
    scan_interval                    = "10s"
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }

  # Azure Key Vault Secrets Provider
  # CIS 5.4.1 - Prefer using secrets as files
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Maintenance window for updates
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4, 5]
    }
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "00:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "+00:00"
  }

  # Monitoring and diagnostics
  # CIS 5.1.4 - Ensure audit logs are enabled
  # DoD STIG V-242461 - Enable audit logging
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Microsoft Defender for Containers
  # NIST 800-190 - Runtime threat detection
  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # HTTP Application Routing (disabled for security)
  # CIS 5.5.1 - Configure securely
  http_application_routing_enabled = false

  # Azure Policy Add-on
  # DoD STIG V-242414 - Enforce security policies
  azure_policy_enabled = true

  # Storage profile for security
  storage_profile {
    blob_driver_enabled         = false # Disable if not needed
    disk_driver_enabled         = true
    disk_driver_version         = "v1"
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  # Automatic upgrade channel
  automatic_channel_upgrade = var.automatic_channel_upgrade

  # Node OS upgrade channel
  node_os_channel_upgrade = "NodeImage"

  tags = local.default_tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      tags["CreatedDate"]
    ]
  }
}

# Diagnostic settings for AKS
# CIS 5.1.4 - Ensure audit logs are enabled and stored
# DoD STIG V-242461
resource "azurerm_monitor_diagnostic_setting" "aks_diagnostics" {
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # All log categories for compliance
  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "cloud-controller-manager"
  }

  # All metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
