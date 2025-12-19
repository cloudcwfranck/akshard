# Additional Node Pools for Workloads
# Separated from system node pool for workload isolation

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  os_sku                = each.value.os_sku
  vnet_subnet_id        = var.subnet_id
  zones                 = each.value.zones
  orchestrator_version  = var.kubernetes_version

  # Scaling configuration
  enable_auto_scaling = each.value.enable_auto_scaling
  min_count           = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count           = each.value.enable_auto_scaling ? each.value.max_count : null
  node_count          = each.value.enable_auto_scaling ? null : each.value.node_count

  # Node configuration
  max_pods        = each.value.max_pods
  os_disk_size_gb = each.value.os_disk_size_gb
  os_disk_type    = "Ephemeral"

  # Labels and taints for workload scheduling
  node_labels = merge(
    each.value.node_labels,
    {
      "nodepool" = each.key
    }
  )
  node_taints = each.value.node_taints

  # Spot instance configuration (if applicable)
  priority        = each.value.priority
  eviction_policy = each.value.priority == "Spot" ? each.value.eviction_policy : null
  spot_max_price  = each.value.priority == "Spot" ? each.value.spot_max_price : null

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
    swap_file_size_mb = 0

    sysctl_config {
      net_ipv4_ip_forward                  = 1
      net_ipv4_conf_all_forwarding         = 1
      net_bridge_bridge_nf_call_iptables   = 1
      net_ipv4_tcp_tw_reuse                = true
      net_ipv4_conf_all_send_redirects     = 0
      net_ipv4_conf_default_send_redirects = 0
      net_ipv4_conf_all_accept_redirects   = 0
      net_ipv4_conf_default_accept_redirects = 0
      vm_max_map_count                     = 262144
      kernel_threads_max                   = 65536
    }
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = merge(
    var.tags,
    {
      "NodePool" = each.key
      "Priority" = each.value.priority
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
