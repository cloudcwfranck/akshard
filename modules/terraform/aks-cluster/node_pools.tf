# User Node Pools for Workload Separation
# Separated from system node pool for workload isolation and cost optimization

# General Workload Node Pool
resource "azurerm_kubernetes_cluster_node_pool" "general" {
  count = var.enable_general_node_pool ? 1 : 0

  name                  = "general"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.general_node_pool_vm_size
  orchestrator_version  = var.kubernetes_version

  # OS Configuration
  os_disk_size_gb   = var.general_node_pool_os_disk_size
  os_disk_type      = var.general_node_pool_os_disk_type
  os_sku            = var.node_os_sku
  kubelet_disk_type = "OS"

  # Scaling configuration
  enable_auto_scaling = true
  min_count          = var.general_node_pool_min_count
  max_count          = var.general_node_pool_max_count
  node_count         = null

  # Network configuration
  vnet_subnet_id = var.aks_subnet_id
  pod_subnet_id  = var.enable_overlay_networking ? null : var.aks_pod_subnet_id
  max_pods       = var.general_node_pool_max_pods

  # High availability
  zones = var.availability_zones

  # Node pool mode
  mode = "User"

  # Node labels for workload targeting
  node_labels = merge(
    {
      workload   = "general"
      nodepool   = "general"
      compliance = "restricted"
    },
    var.general_node_pool_labels
  )

  # Node taints (none for general workload)
  node_taints = var.general_node_pool_taints

  # Upgrade configuration
  temporary_name_for_rotation = "generaltemp"

  upgrade_settings {
    max_surge = "33%"
  }

  # CIS 5.1.5 - Secure kubelet configuration
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
      NodePool             = "general"
      WorkloadType         = "general"
      "kubernetes.io/role" = "worker"
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# GPU-enabled Node Pool (for ML/AI workloads)
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count = var.enable_gpu_node_pool ? 1 : 0

  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.gpu_node_pool_vm_size
  orchestrator_version  = var.kubernetes_version

  # OS Configuration
  os_disk_size_gb   = var.gpu_node_pool_os_disk_size
  os_disk_type      = "Ephemeral"
  os_sku            = var.node_os_sku
  kubelet_disk_type = "OS"

  # Scaling configuration (scale to zero when not in use)
  enable_auto_scaling = true
  min_count          = var.gpu_node_pool_min_count
  max_count          = var.gpu_node_pool_max_count
  node_count         = null

  # Network configuration
  vnet_subnet_id = var.aks_subnet_id
  pod_subnet_id  = var.enable_overlay_networking ? null : var.aks_pod_subnet_id
  max_pods       = var.gpu_node_pool_max_pods

  # High availability
  zones = var.availability_zones

  # Node pool mode
  mode = "User"

  # GPU-specific labels
  node_labels = merge(
    {
      workload                     = "gpu"
      nodepool                     = "gpu"
      "accelerator"                = var.gpu_accelerator_type
      "nvidia.com/gpu.present"     = "true"
      "kubernetes.azure.com/scalesetpriority" = var.gpu_node_pool_priority
    },
    var.gpu_node_pool_labels
  )

  # Taint to prevent non-GPU workloads
  node_taints = concat(
    ["nvidia.com/gpu=true:NoSchedule"],
    var.gpu_node_pool_taints
  )

  # Spot instances (optional for cost savings)
  priority        = var.gpu_node_pool_priority
  eviction_policy = var.gpu_node_pool_priority == "Spot" ? "Delete" : null
  spot_max_price  = var.gpu_node_pool_priority == "Spot" ? var.gpu_spot_max_price : null

  # Upgrade configuration
  temporary_name_for_rotation = "gputemp"

  upgrade_settings {
    max_surge = "33%"
  }

  # CIS 5.1.5 - Secure kubelet configuration
  kubelet_config {
    cpu_manager_policy        = "static" # Required for GPU
    topology_manager_policy   = "best-effort"
    allowed_unsafe_sysctls    = []
    container_log_max_size_mb = 50
    container_log_max_line    = 5000
    pod_max_pid               = 4096
  }

  # Linux OS configuration
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

  tags = merge(
    local.default_tags,
    {
      NodePool             = "gpu"
      WorkloadType         = "gpu"
      Accelerator          = var.gpu_accelerator_type
      Priority             = var.gpu_node_pool_priority
      "kubernetes.io/role" = "worker-gpu"
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Memory-Optimized Node Pool (for data processing, caching)
resource "azurerm_kubernetes_cluster_node_pool" "highmem" {
  count = var.enable_memory_optimized_node_pool ? 1 : 0

  name                  = "highmem"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.memory_optimized_node_pool_vm_size
  orchestrator_version  = var.kubernetes_version

  # OS Configuration
  os_disk_size_gb   = var.memory_optimized_node_pool_os_disk_size
  os_disk_type      = var.memory_optimized_node_pool_os_disk_type
  os_sku            = var.node_os_sku
  kubelet_disk_type = "OS"

  # Scaling configuration
  enable_auto_scaling = true
  min_count          = var.memory_optimized_node_pool_min_count
  max_count          = var.memory_optimized_node_pool_max_count
  node_count         = null

  # Network configuration
  vnet_subnet_id = var.aks_subnet_id
  pod_subnet_id  = var.enable_overlay_networking ? null : var.aks_pod_subnet_id
  max_pods       = var.memory_optimized_node_pool_max_pods

  # High availability
  zones = var.availability_zones

  # Node pool mode
  mode = "User"

  # Memory-optimized labels
  node_labels = merge(
    {
      workload   = "memory-intensive"
      nodepool   = "highmem"
      vmsize     = var.memory_optimized_node_pool_vm_size
    },
    var.memory_optimized_node_pool_labels
  )

  # Taint to prevent general workloads
  node_taints = concat(
    ["workload=memory-intensive:NoSchedule"],
    var.memory_optimized_node_pool_taints
  )

  # Upgrade configuration
  temporary_name_for_rotation = "highmemtemp"

  upgrade_settings {
    max_surge = "33%"
  }

  # CIS 5.1.5 - Secure kubelet configuration
  kubelet_config {
    cpu_manager_policy        = local.kubelet_config.cpu_manager_policy
    topology_manager_policy   = local.kubelet_config.topology_manager_policy
    allowed_unsafe_sysctls    = local.kubelet_config.allowed_unsafe_sysctls
    container_log_max_size_mb = local.kubelet_config.container_log_max_size_mb
    container_log_max_line    = local.kubelet_config.container_log_max_line
    pod_max_pid               = local.kubelet_config.pod_max_pid
  }

  # Linux OS configuration
  linux_os_config {
    swap_file_size_mb = 0

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
      NodePool             = "highmem"
      WorkloadType         = "memory-intensive"
      "kubernetes.io/role" = "worker-highmem"
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Compute-Optimized Node Pool (for CPU-intensive workloads)
resource "azurerm_kubernetes_cluster_node_pool" "compute" {
  count = var.enable_compute_optimized_node_pool ? 1 : 0

  name                  = "compute"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.compute_optimized_node_pool_vm_size
  orchestrator_version  = var.kubernetes_version

  # OS Configuration
  os_disk_size_gb   = var.compute_optimized_node_pool_os_disk_size
  os_disk_type      = "Ephemeral"
  os_sku            = var.node_os_sku
  kubelet_disk_type = "OS"

  # Scaling configuration
  enable_auto_scaling = true
  min_count          = var.compute_optimized_node_pool_min_count
  max_count          = var.compute_optimized_node_pool_max_count
  node_count         = null

  # Network configuration
  vnet_subnet_id = var.aks_subnet_id
  pod_subnet_id  = var.enable_overlay_networking ? null : var.aks_pod_subnet_id
  max_pods       = var.compute_optimized_node_pool_max_pods

  # High availability
  zones = var.availability_zones

  # Node pool mode
  mode = "User"

  # Compute-optimized labels
  node_labels = merge(
    {
      workload   = "compute-intensive"
      nodepool   = "compute"
      vmsize     = var.compute_optimized_node_pool_vm_size
    },
    var.compute_optimized_node_pool_labels
  )

  # Taint to prevent general workloads
  node_taints = concat(
    ["workload=compute-intensive:NoSchedule"],
    var.compute_optimized_node_pool_taints
  )

  # Upgrade configuration
  temporary_name_for_rotation = "computetemp"

  upgrade_settings {
    max_surge = "33%"
  }

  # CIS 5.1.5 - Secure kubelet configuration with static CPU manager
  kubelet_config {
    cpu_manager_policy        = "static" # Pin CPUs for performance
    topology_manager_policy   = "best-effort"
    allowed_unsafe_sysctls    = []
    container_log_max_size_mb = 50
    container_log_max_line    = 5000
    pod_max_pid               = 4096
  }

  # Linux OS configuration
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

  tags = merge(
    local.default_tags,
    {
      NodePool             = "compute"
      WorkloadType         = "compute-intensive"
      "kubernetes.io/role" = "worker-compute"
    }
  )

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
