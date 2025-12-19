# Enterprise-Grade Hardened AKS Cluster Module
# Implements CIS Benchmark v1.8, DoD STIG v1r12, NIST 800-190, FedRAMP controls

# Cluster Managed Identity
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = local.cluster_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.default_tags
}

# Kubelet Managed Identity (for ACR authentication)
resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = local.kubelet_identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.default_tags
}

# AKS Cluster - Enterprise Hardened Configuration
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix != "" ? var.dns_prefix : var.cluster_name
  kubernetes_version  = var.kubernetes_version
  node_resource_group = local.node_resource_group

  # SKU: Standard (99.9% SLA) or Premium (99.95% SLA + longer support)
  sku_tier = var.sku_tier

  # Automatic upgrade channel
  automatic_channel_upgrade = var.automatic_channel_upgrade
  node_os_channel_upgrade   = var.node_os_channel_upgrade

  # CIS 5.1.1 - Ensure RBAC is enabled
  # DoD STIG V-242376 - Enable RBAC
  role_based_access_control_enabled = true

  # CIS 3.2.1 - Ensure API server is not exposed to the internet
  # DoD STIG V-242418 - API server must be protected
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_dns_zone_id

  # DoD STIG V-242383 - Disable local accounts (force Azure AD)
  local_account_disabled = var.disable_local_accounts

  # CIS 5.2.1 - Minimize pod access to secrets
  # Workload Identity (OIDC federation - no service principal keys)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Image cleaner to remove unused images
  image_cleaner_enabled        = var.enable_image_cleaner
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # HTTP application routing (disabled for security)
  http_application_routing_enabled = false

  # Run command (disabled for security in production)
  run_command_enabled = var.enable_run_command

  # System Node Pool (critical addons only)
  default_node_pool {
    name    = local.system_node_pool.name
    vm_size = local.system_node_pool.vm_size

    # OS Configuration
    os_disk_size_gb   = local.system_node_pool.os_disk_size_gb
    os_disk_type      = local.system_node_pool.os_disk_type
    os_sku            = local.system_node_pool.os_sku
    kubelet_disk_type = local.system_node_pool.kubelet_disk_type

    # Scaling configuration
    enable_auto_scaling = local.system_node_pool.enable_auto_scaling
    min_count          = local.system_node_pool.min_count
    max_count          = local.system_node_pool.max_count
    node_count         = null # Must be null when auto-scaling is enabled

    # Network configuration
    vnet_subnet_id = local.system_node_pool.vnet_subnet_id
    pod_subnet_id  = local.system_node_pool.pod_subnet_id
    max_pods       = local.system_node_pool.max_pods

    # High availability - spread across availability zones
    zones = local.system_node_pool.zones

    # System pool taint - only critical addons
    only_critical_addons_enabled = local.system_node_pool.only_critical_addons_enabled

    # Upgrade configuration
    orchestrator_version        = var.kubernetes_version
    temporary_name_for_rotation = "${local.system_node_pool.name}tmp"

    upgrade_settings {
      max_surge = local.system_node_pool.upgrade_settings.max_surge
    }

    # CIS 5.1.5 - Ensure kubelet configuration is secure
    kubelet_config {
      cpu_manager_policy        = local.kubelet_config.cpu_manager_policy
      topology_manager_policy   = local.kubelet_config.topology_manager_policy
      allowed_unsafe_sysctls    = local.kubelet_config.allowed_unsafe_sysctls
      container_log_max_size_mb = local.kubelet_config.container_log_max_size_mb
      container_log_max_line    = local.kubelet_config.container_log_max_line
      pod_max_pid               = local.kubelet_config.pod_max_pid
    }

    # CIS 4.1.1 - Linux OS hardening
    linux_os_config {
      swap_file_size_mb = local.linux_os_config.swap_file_size_mb

      sysctl_config {
        net_ipv4_ip_forward                  = local.linux_os_config.sysctl_config.net_ipv4_ip_forward
        net_ipv4_conf_all_forwarding         = local.linux_os_config.sysctl_config.net_ipv4_conf_all_forwarding
        net_bridge_bridge_nf_call_iptables   = local.linux_os_config.sysctl_config.net_bridge_bridge_nf_call_iptables
        net_ipv4_tcp_tw_reuse                = local.linux_os_config.sysctl_config.net_ipv4_tcp_tw_reuse
        net_ipv4_conf_all_send_redirects     = local.linux_os_config.sysctl_config.net_ipv4_conf_all_send_redirects
        net_ipv4_conf_default_send_redirects = local.linux_os_config.sysctl_config.net_ipv4_conf_default_send_redirects
        net_ipv4_conf_all_accept_redirects   = local.linux_os_config.sysctl_config.net_ipv4_conf_all_accept_redirects
        net_ipv4_conf_default_accept_redirects = local.linux_os_config.sysctl_config.net_ipv4_conf_default_accept_redirects
        vm_max_map_count                     = local.linux_os_config.sysctl_config.vm_max_map_count
        kernel_threads_max                   = local.linux_os_config.sysctl_config.kernel_threads_max
      }
    }

    tags = merge(
      local.default_tags,
      {
        NodePool                 = "system"
        CriticalAddonsOnly       = "true"
        "kubernetes.io/role"     = "system"
      }
    )
  }

  # Cluster Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  # Kubelet Identity (for ACR pull)
  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  # CIS 5.3.1 - Network configuration with CNI supporting Network Policies
  network_profile {
    network_plugin      = var.network_plugin
    network_plugin_mode = local.network_plugin_mode
    network_policy      = var.network_policy

    # Service and pod networking
    dns_service_ip = local.dns_service_ip
    service_cidr   = local.service_cidr
    pod_cidr       = local.pod_cidr

    # Outbound connectivity
    outbound_type     = local.outbound_type
    load_balancer_sku = "standard"

    # Load balancer configuration
    load_balancer_profile {
      managed_outbound_ip_count   = var.use_user_defined_routing || var.enable_nat_gateway ? 0 : var.managed_outbound_ip_count
      outbound_ip_address_ids     = var.outbound_ip_address_ids
      outbound_ip_prefix_ids      = var.outbound_ip_prefix_ids
      idle_timeout_in_minutes     = 30
      managed_outbound_ipv6_count = 0
    }
  }

  # API Server Access Profile (for private cluster)
  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [1] : []
    content {
      authorized_ip_ranges     = var.api_server_authorized_ip_ranges
      vnet_integration_enabled = var.enable_vnet_integration
      subnet_id                = var.api_server_subnet_id
    }
  }

  # CIS 5.1.1 - Azure AD Integration for RBAC
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = var.enable_azure_rbac
    tenant_id              = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
  }

  # Cluster Autoscaler Profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
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
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = true
  }

  # CIS 5.4.1 - Azure Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = var.enable_secret_rotation
    secret_rotation_interval = var.secret_rotation_interval
  }

  # CIS 5.1.4 - OMS Agent for Log Analytics
  # DoD STIG V-242461 - Enable audit logging
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # NIST 800-190 - Runtime threat detection
  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # DoD STIG V-242414 - Azure Policy enforcement
  azure_policy_enabled = var.enable_azure_policy

  # Maintenance windows for updates
  maintenance_window {
    allowed {
      day   = var.maintenance_window_day
      hours = var.maintenance_window_hours
    }
  }

  maintenance_window_auto_upgrade {
    frequency    = "Weekly"
    interval     = 1
    duration     = 4
    day_of_week  = var.maintenance_window_day
    start_time   = var.maintenance_window_start_time
    utc_offset   = var.maintenance_window_utc_offset
    not_allowed {
      start = var.maintenance_window_not_allowed_start
      end   = var.maintenance_window_not_allowed_end
    }
  }

  maintenance_window_node_os {
    frequency    = "Weekly"
    interval     = 1
    duration     = 4
    day_of_week  = var.maintenance_window_day
    start_time   = var.maintenance_window_node_os_start_time
    utc_offset   = var.maintenance_window_utc_offset
  }

  # Storage profile
  storage_profile {
    blob_driver_enabled         = var.enable_blob_driver
    disk_driver_enabled         = true
    disk_driver_version         = "v1"
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  # Service mesh (optional)
  dynamic "service_mesh_profile" {
    for_each = var.enable_service_mesh ? [1] : []
    content {
      mode                             = var.service_mesh_mode
      internal_ingress_gateway_enabled = var.service_mesh_internal_ingress_enabled
      external_ingress_gateway_enabled = var.service_mesh_external_ingress_enabled
    }
  }

  # Web App Routing (optional, alternative to service mesh)
  dynamic "web_app_routing" {
    for_each = var.enable_web_app_routing ? [1] : []
    content {
      dns_zone_id = var.web_app_routing_dns_zone_id
    }
  }

  tags = local.default_tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      tags["CreatedDate"],
      kubernetes_version, # Managed by automatic upgrades
    ]

    precondition {
      condition     = var.private_cluster_enabled == true
      error_message = "Private cluster must be enabled for security compliance (CIS 3.2.1)"
    }

    precondition {
      condition     = var.disable_local_accounts == true
      error_message = "Local accounts must be disabled for security compliance (DoD STIG V-242383)"
    }

    precondition {
      condition     = length(var.admin_group_object_ids) > 0
      error_message = "At least one Azure AD admin group must be specified"
    }
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  depends_on = [
    azurerm_user_assigned_identity.aks_identity,
    azurerm_user_assigned_identity.kubelet_identity,
  ]
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}
