# Variables for Enterprise-Grade Hardened AKS Cluster Module
# Organized by: Core, Networking, Node Pools, Security, Monitoring, Add-ons

# ============================================================================
# REQUIRED VARIABLES
# ============================================================================

variable "cluster_name" {
  description = "Name of the AKS cluster (3-63 characters, lowercase alphanumeric and hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$", var.cluster_name))
    error_message = "Cluster name must be 3-63 characters, start/end with alphanumeric, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where AKS will be deployed"
  type        = string
}

variable "location" {
  description = "Azure region for AKS cluster"
  type        = string

  validation {
    condition = can(regex("^(eastus|eastus2|westus|westus2|westus3|centralus|northcentralus|southcentralus|westcentralus|canadacentral|canadaeast|brazilsouth|uksouth|ukwest|northeurope|westeurope|francecentral|germanywestcentral|norwayeast|switzerlandnorth|swedencentral|eastasia|southeastasia|japaneast|japanwest|australiaeast|australiasoutheast|centralindia|southindia|koreacentral|southafricanorth|uaenorth|usgovvirginia|usgovarizona|usgovtexas|usdodeast|usdodcentral)$", var.location))
    error_message = "Location must be a valid Azure region."
  }
}

variable "aks_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", var.aks_subnet_id))
    error_message = "Must be a valid Azure subnet resource ID."
  }
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring and diagnostic logs"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/.+/resourcegroups/.+/providers/microsoft.operationalinsights/workspaces/.+$", var.log_analytics_workspace_id))
    error_message = "Must be a valid Log Analytics Workspace resource ID."
  }
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster administrators"
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one admin group must be specified for security compliance."
  }

  validation {
    condition     = alltrue([for id in var.admin_group_object_ids : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "All admin group IDs must be valid GUIDs."
  }
}

# ============================================================================
# CORE CLUSTER CONFIGURATION
# ============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.28.3"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y.Z"
  }
}

variable "sku_tier" {
  description = "SKU tier for AKS cluster (Free, Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Free, Standard, or Premium. Standard or Premium required for production (99.9%+ SLA)."
  }
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster (defaults to cluster_name if empty)"
  type        = string
  default     = ""
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (none, patch, stable, rapid, node-image)"
  type        = string
  default     = "patch"

  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_channel_upgrade)
    error_message = "Must be one of: none, patch, stable, rapid, node-image."
  }
}

variable "node_os_channel_upgrade" {
  description = "Auto-upgrade channel for node OS images (Unmanaged, SecurityPatch, NodeImage)"
  type        = string
  default     = "NodeImage"

  validation {
    condition     = contains(["Unmanaged", "SecurityPatch", "NodeImage"], var.node_os_channel_upgrade)
    error_message = "Must be one of: Unmanaged, SecurityPatch, NodeImage."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "private_cluster_enabled" {
  description = "Enable private AKS cluster (CIS 3.2.1 - required for compliance)"
  type        = bool
  default     = true
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID for private cluster (auto-created if empty)"
  type        = string
  default     = ""
}

variable "disable_local_accounts" {
  description = "Disable local accounts to enforce Azure AD authentication (DoD STIG V-242383)"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access (CIDR notation) - empty for no public access"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.api_server_authorized_ip_ranges : can(cidrhost(cidr, 0))])
    error_message = "All IP ranges must be valid CIDR notation."
  }
}

variable "enable_vnet_integration" {
  description = "Enable API server VNet integration"
  type        = bool
  default     = false
}

variable "api_server_subnet_id" {
  description = "Subnet ID for API server VNet integration"
  type        = string
  default     = ""
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "tenant_id" {
  description = "Azure AD tenant ID (auto-detected if empty)"
  type        = string
  default     = ""
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on (DoD STIG V-242414)"
  type        = bool
  default     = true
}

variable "enable_secret_rotation" {
  description = "Enable automatic secret rotation for Key Vault CSI driver"
  type        = bool
  default     = true
}

variable "secret_rotation_interval" {
  description = "Secret rotation interval for Key Vault CSI driver"
  type        = string
  default     = "2m"
}

variable "enable_run_command" {
  description = "Enable run command (disable for production security)"
  type        = bool
  default     = false
}

variable "enable_image_cleaner" {
  description = "Enable image cleaner to remove unused images"
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "Image cleaner interval in hours (24-2160)"
  type        = number
  default     = 48

  validation {
    condition     = var.image_cleaner_interval_hours >= 24 && var.image_cleaner_interval_hours <= 2160
    error_message = "Image cleaner interval must be between 24 and 2160 hours."
  }
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "network_plugin" {
  description = "Network plugin (azure, kubenet, none)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_plugin)
    error_message = "Network plugin must be azure, kubenet, or none."
  }
}

variable "enable_overlay_networking" {
  description = "Enable Azure CNI Overlay mode (requires AKS 1.22+)"
  type        = bool
  default     = true
}

variable "network_policy" {
  description = "Network policy plugin (azure, calico, cilium, none)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "calico", "cilium", "none"], var.network_policy)
    error_message = "Network policy must be azure, calico, cilium, or none."
  }
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be valid CIDR notation."
  }
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service (must be within service_cidr)"
  type        = string
  default     = "172.16.0.10"

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IP address."
  }
}

variable "pod_cidr" {
  description = "CIDR for pod networking (overlay mode only)"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "Pod CIDR must be valid CIDR notation."
  }
}

variable "aks_pod_subnet_id" {
  description = "Separate subnet ID for pod networking (non-overlay mode)"
  type        = string
  default     = ""
}

variable "use_user_defined_routing" {
  description = "Use User Defined Routing (UDR) for outbound traffic"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound connectivity"
  type        = bool
  default     = false
}

variable "managed_outbound_ip_count" {
  description = "Number of managed outbound IPs for load balancer (0 if using UDR/NAT Gateway)"
  type        = number
  default     = 0

  validation {
    condition     = var.managed_outbound_ip_count >= 0 && var.managed_outbound_ip_count <= 16
    error_message = "Managed outbound IP count must be between 0 and 16."
  }
}

variable "outbound_ip_address_ids" {
  description = "List of outbound public IP address IDs"
  type        = list(string)
  default     = []
}

variable "outbound_ip_prefix_ids" {
  description = "List of outbound public IP prefix IDs"
  type        = list(string)
  default     = []
}

# ============================================================================
# SYSTEM NODE POOL CONFIGURATION
# ============================================================================

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool (minimum: Standard_D4s_v5)"
  type        = string
  default     = "Standard_D4s_v5"
}

variable "system_node_pool_os_disk_size" {
  description = "OS disk size in GB for system nodes"
  type        = number
  default     = 128

  validation {
    condition     = var.system_node_pool_os_disk_size >= 30 && var.system_node_pool_os_disk_size <= 2048
    error_message = "OS disk size must be between 30 and 2048 GB."
  }
}

variable "system_node_pool_os_disk_type" {
  description = "OS disk type (Ephemeral, Managed)"
  type        = string
  default     = "Ephemeral"

  validation {
    condition     = contains(["Ephemeral", "Managed"], var.system_node_pool_os_disk_type)
    error_message = "OS disk type must be Ephemeral or Managed."
  }
}

variable "system_node_pool_min_count" {
  description = "Minimum number of system nodes (minimum 3 for HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.system_node_pool_min_count >= 3
    error_message = "System node pool must have minimum 3 nodes for high availability."
  }
}

variable "system_node_pool_max_count" {
  description = "Maximum number of system nodes"
  type        = number
  default     = 6

  validation {
    condition     = var.system_node_pool_max_count >= var.system_node_pool_min_count
    error_message = "Max count must be greater than or equal to min count."
  }
}

variable "system_node_pool_max_pods" {
  description = "Maximum number of pods per system node"
  type        = number
  default     = 100

  validation {
    condition     = var.system_node_pool_max_pods >= 10 && var.system_node_pool_max_pods <= 250
    error_message = "Max pods must be between 10 and 250."
  }
}

variable "node_os_sku" {
  description = "Node OS SKU (AzureLinux, Ubuntu, Windows2019, Windows2022)"
  type        = string
  default     = "AzureLinux"

  validation {
    condition     = contains(["AzureLinux", "Ubuntu", "Windows2019", "Windows2022"], var.node_os_sku)
    error_message = "Node OS SKU must be AzureLinux, Ubuntu, Windows2019, or Windows2022."
  }
}

variable "availability_zones" {
  description = "Availability zones for node pools"
  type        = list(string)
  default     = ["1", "2", "3"]

  validation {
    condition     = alltrue([for z in var.availability_zones : contains(["1", "2", "3"], z)])
    error_message = "Availability zones must be 1, 2, or 3."
  }
}

# ============================================================================
# GENERAL WORKLOAD NODE POOL
# ============================================================================

variable "enable_general_node_pool" {
  description = "Enable general workload node pool"
  type        = bool
  default     = true
}

variable "general_node_pool_vm_size" {
  description = "VM size for general workload node pool"
  type        = string
  default     = "Standard_D8s_v5"
}

variable "general_node_pool_os_disk_size" {
  description = "OS disk size in GB for general nodes"
  type        = number
  default     = 150
}

variable "general_node_pool_os_disk_type" {
  description = "OS disk type for general nodes"
  type        = string
  default     = "Ephemeral"
}

variable "general_node_pool_min_count" {
  description = "Minimum number of general workload nodes"
  type        = number
  default     = 2
}

variable "general_node_pool_max_count" {
  description = "Maximum number of general workload nodes"
  type        = number
  default     = 20
}

variable "general_node_pool_max_pods" {
  description = "Maximum pods per general workload node"
  type        = number
  default     = 100
}

variable "general_node_pool_labels" {
  description = "Additional labels for general node pool"
  type        = map(string)
  default     = {}
}

variable "general_node_pool_taints" {
  description = "Taints for general node pool"
  type        = list(string)
  default     = []
}

# ============================================================================
# GPU NODE POOL
# ============================================================================

variable "enable_gpu_node_pool" {
  description = "Enable GPU-accelerated node pool"
  type        = bool
  default     = false
}

variable "gpu_node_pool_vm_size" {
  description = "VM size for GPU node pool"
  type        = string
  default     = "Standard_NC6s_v3"
}

variable "gpu_node_pool_os_disk_size" {
  description = "OS disk size in GB for GPU nodes"
  type        = number
  default     = 200
}

variable "gpu_node_pool_min_count" {
  description = "Minimum GPU nodes (0 for scale-to-zero)"
  type        = number
  default     = 0
}

variable "gpu_node_pool_max_count" {
  description = "Maximum GPU nodes"
  type        = number
  default     = 5
}

variable "gpu_node_pool_max_pods" {
  description = "Maximum pods per GPU node"
  type        = number
  default     = 30
}

variable "gpu_accelerator_type" {
  description = "GPU accelerator type"
  type        = string
  default     = "nvidia-tesla-v100"
}

variable "gpu_node_pool_priority" {
  description = "Node priority (Regular or Spot)"
  type        = string
  default     = "Regular"

  validation {
    condition     = contains(["Regular", "Spot"], var.gpu_node_pool_priority)
    error_message = "Priority must be Regular or Spot."
  }
}

variable "gpu_spot_max_price" {
  description = "Max price for Spot GPU nodes (-1 for pay up to regular price)"
  type        = number
  default     = -1
}

variable "gpu_node_pool_labels" {
  description = "Additional labels for GPU node pool"
  type        = map(string)
  default     = {}
}

variable "gpu_node_pool_taints" {
  description = "Additional taints for GPU node pool"
  type        = list(string)
  default     = []
}

# ============================================================================
# MEMORY-OPTIMIZED NODE POOL
# ============================================================================

variable "enable_memory_optimized_node_pool" {
  description = "Enable memory-optimized node pool"
  type        = bool
  default     = false
}

variable "memory_optimized_node_pool_vm_size" {
  description = "VM size for memory-optimized nodes"
  type        = string
  default     = "Standard_E8s_v5"
}

variable "memory_optimized_node_pool_os_disk_size" {
  description = "OS disk size for memory-optimized nodes"
  type        = number
  default     = 150
}

variable "memory_optimized_node_pool_os_disk_type" {
  description = "OS disk type for memory-optimized nodes"
  type        = string
  default     = "Ephemeral"
}

variable "memory_optimized_node_pool_min_count" {
  description = "Minimum memory-optimized nodes"
  type        = number
  default     = 0
}

variable "memory_optimized_node_pool_max_count" {
  description = "Maximum memory-optimized nodes"
  type        = number
  default     = 10
}

variable "memory_optimized_node_pool_max_pods" {
  description = "Maximum pods per memory-optimized node"
  type        = number
  default     = 100
}

variable "memory_optimized_node_pool_labels" {
  description = "Additional labels for memory-optimized node pool"
  type        = map(string)
  default     = {}
}

variable "memory_optimized_node_pool_taints" {
  description = "Additional taints for memory-optimized node pool"
  type        = list(string)
  default     = []
}

# ============================================================================
# COMPUTE-OPTIMIZED NODE POOL
# ============================================================================

variable "enable_compute_optimized_node_pool" {
  description = "Enable compute-optimized node pool"
  type        = bool
  default     = false
}

variable "compute_optimized_node_pool_vm_size" {
  description = "VM size for compute-optimized nodes"
  type        = string
  default     = "Standard_F16s_v2"
}

variable "compute_optimized_node_pool_os_disk_size" {
  description = "OS disk size for compute-optimized nodes"
  type        = number
  default     = 150
}

variable "compute_optimized_node_pool_min_count" {
  description = "Minimum compute-optimized nodes"
  type        = number
  default     = 0
}

variable "compute_optimized_node_pool_max_count" {
  description = "Maximum compute-optimized nodes"
  type        = number
  default     = 10
}

variable "compute_optimized_node_pool_max_pods" {
  description = "Maximum pods per compute-optimized node"
  type        = number
  default     = 100
}

variable "compute_optimized_node_pool_labels" {
  description = "Additional labels for compute-optimized node pool"
  type        = map(string)
  default     = {}
}

variable "compute_optimized_node_pool_taints" {
  description = "Additional taints for compute-optimized node pool"
  type        = list(string)
  default     = []
}

# ============================================================================
# NETWORKING RESOURCES
# ============================================================================

variable "vnet_id" {
  description = "VNet ID for private DNS zone link"
  type        = string
  default     = ""
}

variable "create_nsg" {
  description = "Create NSG for AKS subnet"
  type        = bool
  default     = false
}

variable "associate_nsg_to_subnet" {
  description = "Associate NSG to AKS subnet"
  type        = bool
  default     = false
}

variable "allow_application_gateway" {
  description = "Allow inbound from Application Gateway"
  type        = bool
  default     = false
}

variable "application_gateway_subnet_cidrs" {
  description = "Application Gateway subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "create_route_table" {
  description = "Create route table for UDR"
  type        = bool
  default     = false
}

variable "associate_route_table_to_subnet" {
  description = "Associate route table to subnet"
  type        = bool
  default     = false
}

variable "disable_bgp_route_propagation" {
  description = "Disable BGP route propagation"
  type        = bool
  default     = false
}

variable "default_route_next_hop_ip" {
  description = "Next hop IP for default route (Azure Firewall)"
  type        = string
  default     = ""
}

variable "create_azure_service_routes" {
  description = "Create routes for Azure services"
  type        = bool
  default     = false
}

variable "azure_service_routes" {
  description = "Map of Azure service routes"
  type = map(object({
    address_prefix = string
    next_hop_type  = string
  }))
  default = {}
}

variable "create_nat_gateway" {
  description = "Create NAT Gateway"
  type        = bool
  default     = false
}

variable "associate_nat_gateway_to_subnet" {
  description = "Associate NAT Gateway to subnet"
  type        = bool
  default     = false
}

variable "nat_gateway_public_ip_prefix_length" {
  description = "Public IP prefix length for NAT Gateway (28-31)"
  type        = number
  default     = 30

  validation {
    condition     = var.nat_gateway_public_ip_prefix_length >= 28 && var.nat_gateway_public_ip_prefix_length <= 31
    error_message = "Prefix length must be between 28 and 31."
  }
}

variable "nat_gateway_idle_timeout_minutes" {
  description = "NAT Gateway idle timeout in minutes"
  type        = number
  default     = 10

  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 120
    error_message = "Idle timeout must be between 4 and 120 minutes."
  }
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway"
  type        = list(string)
  default     = ["1"]
}

variable "create_private_dns_zone" {
  description = "Create private DNS zone for private cluster"
  type        = bool
  default     = false
}

variable "link_to_hub_vnet" {
  description = "Link private DNS zone to hub VNet"
  type        = bool
  default     = false
}

variable "hub_vnet_id" {
  description = "Hub VNet ID for DNS zone link"
  type        = string
  default     = ""
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection"
  type        = bool
  default     = false
}

# ============================================================================
# RBAC AND ACCESS CONTROL
# ============================================================================

variable "viewer_group_object_ids" {
  description = "Azure AD group IDs for read-only access"
  type        = list(string)
  default     = []
}

variable "developer_group_object_ids" {
  description = "Azure AD group IDs for developer access"
  type        = list(string)
  default     = []
}

variable "grant_kubernetes_cluster_admin" {
  description = "Grant Kubernetes cluster-admin to admin groups"
  type        = bool
  default     = true
}

variable "grant_developer_access" {
  description = "Grant developer write access"
  type        = bool
  default     = false
}

variable "container_registry_id" {
  description = "Azure Container Registry resource ID for AcrPull"
  type        = string
  default     = ""
}

variable "key_vault_id" {
  description = "Azure Key Vault resource ID"
  type        = string
  default     = ""
}

variable "resource_group_id" {
  description = "Resource group ID for managed identity operator"
  type        = string
  default     = ""
}

variable "node_resource_group_id" {
  description = "Node resource group ID (MC_*)"
  type        = string
  default     = ""
}

variable "enable_separate_oms_identity" {
  description = "Use separate identity for OMS agent"
  type        = bool
  default     = false
}

variable "enable_workload_identity_rbac" {
  description = "Grant managed identity operator for workload identity"
  type        = bool
  default     = false
}

variable "grant_vm_contributor_role" {
  description = "Grant VM Contributor role for node management"
  type        = bool
  default     = false
}

variable "grant_private_dns_contributor" {
  description = "Grant Private DNS Zone Contributor"
  type        = bool
  default     = false
}

variable "create_custom_namespace_admin_role" {
  description = "Create custom namespace admin role"
  type        = bool
  default     = false
}

# ============================================================================
# MONITORING AND ALERTING
# ============================================================================

variable "diagnostic_storage_account_id" {
  description = "Storage account ID for diagnostic logs"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_resource_group" {
  description = "Log Analytics workspace resource group"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable Container Insights solution"
  type        = bool
  default     = true
}

variable "create_action_group" {
  description = "Create action group for alerts"
  type        = bool
  default     = false
}

variable "existing_action_group_id" {
  description = "Existing action group ID"
  type        = string
  default     = ""
}

variable "alert_email_receivers" {
  description = "Email receivers for alerts"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "alert_webhook_receivers" {
  description = "Webhook receivers for alerts"
  type = list(object({
    name        = string
    service_uri = string
  }))
  default = []
}

variable "create_metric_alerts" {
  description = "Create metric alerts"
  type        = bool
  default     = false
}

variable "create_log_alerts" {
  description = "Create log query alerts"
  type        = bool
  default     = false
}

variable "node_cpu_alert_threshold" {
  description = "Node CPU alert threshold percentage"
  type        = number
  default     = 80
}

variable "node_memory_alert_threshold" {
  description = "Node memory alert threshold percentage"
  type        = number
  default     = 80
}

variable "pod_count_alert_threshold" {
  description = "Pod count alert threshold"
  type        = number
  default     = 1000
}

# ============================================================================
# ADD-ONS AND FEATURES
# ============================================================================

variable "enable_service_mesh" {
  description = "Enable service mesh (Istio)"
  type        = bool
  default     = false
}

variable "service_mesh_mode" {
  description = "Service mesh mode (Istio, Disabled)"
  type        = string
  default     = "Istio"
}

variable "service_mesh_internal_ingress_enabled" {
  description = "Enable internal ingress gateway"
  type        = bool
  default     = true
}

variable "service_mesh_external_ingress_enabled" {
  description = "Enable external ingress gateway"
  type        = bool
  default     = false
}

variable "enable_web_app_routing" {
  description = "Enable web app routing"
  type        = bool
  default     = false
}

variable "web_app_routing_dns_zone_id" {
  description = "DNS zone ID for web app routing"
  type        = string
  default     = ""
}

variable "enable_blob_driver" {
  description = "Enable blob CSI driver"
  type        = bool
  default     = false
}

# ============================================================================
# MAINTENANCE WINDOWS
# ============================================================================

variable "maintenance_window_day" {
  description = "Day of week for maintenance (Sunday-Saturday)"
  type        = string
  default     = "Sunday"
}

variable "maintenance_window_hours" {
  description = "Hours for maintenance window"
  type        = list(number)
  default     = [0, 1, 2, 3, 4, 5]
}

variable "maintenance_window_start_time" {
  description = "Start time for auto-upgrade maintenance (HH:MM)"
  type        = string
  default     = "00:00"
}

variable "maintenance_window_node_os_start_time" {
  description = "Start time for node OS maintenance (HH:MM)"
  type        = string
  default     = "04:00"
}

variable "maintenance_window_utc_offset" {
  description = "UTC offset for maintenance window (+/-HH:MM)"
  type        = string
  default     = "+00:00"
}

variable "maintenance_window_not_allowed_start" {
  description = "Start date for not-allowed maintenance period (YYYY-MM-DD)"
  type        = string
  default     = ""
}

variable "maintenance_window_not_allowed_end" {
  description = "End date for not-allowed maintenance period (YYYY-MM-DD)"
  type        = string
  default     = ""
}

# ============================================================================
# COMPLIANCE AND TAGGING
# ============================================================================

variable "data_classification" {
  description = "Data classification level"
  type        = string
  default     = "Internal"

  validation {
    condition     = contains(["Public", "Internal", "Confidential", "Restricted"], var.data_classification)
    error_message = "Data classification must be Public, Internal, Confidential, or Restricted."
  }
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
