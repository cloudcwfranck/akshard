# Variables for AKS Cluster Module

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.cluster_name))
    error_message = "Cluster name must be 3-63 characters long and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = null
}

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
  description = "SKU tier for AKS cluster - Free, Standard, or Premium"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Free, Standard, or Premium."
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

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "api_subnet_id" {
  description = "Subnet ID for API server VNet integration"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster administrators"
  type        = list(string)
  default     = []
}

# Private cluster settings
variable "private_cluster_enabled" {
  description = "Enable private AKS cluster (CIS 3.2.1)"
  type        = bool
  default     = true
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Enable public FQDN for private cluster"
  type        = bool
  default     = false
}

variable "vnet_integration_enabled" {
  description = "Enable VNet integration for API server"
  type        = bool
  default     = false
}

# Security settings
variable "disable_local_accounts" {
  description = "Disable local accounts (DoD STIG V-242383)"
  type        = bool
  default     = true
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access (CIDR format)"
  type        = list(string)
  default     = []
}

variable "image_cleaner_interval_hours" {
  description = "Interval in hours for image cleaner"
  type        = number
  default     = 48

  validation {
    condition     = var.image_cleaner_interval_hours >= 24 && var.image_cleaner_interval_hours <= 2160
    error_message = "Image cleaner interval must be between 24 and 2160 hours."
  }
}

# Default node pool configuration
variable "default_node_pool" {
  description = "Configuration for the default system node pool"
  type = object({
    name                = string
    vm_size             = string
    os_sku              = string
    zones               = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_count          = number
    max_pods            = number
    os_disk_size_gb     = number
  })

  default = {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    os_sku              = "AzureLinux" # CBL-Mariner based, hardened
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6
    node_count          = 3
    max_pods            = 30
    os_disk_size_gb     = 100
  }
}

# Network configuration
variable "network_profile" {
  description = "Network profile configuration for AKS"
  type = object({
    dns_service_ip    = string
    service_cidr      = string
    pod_cidr          = string
    outbound_type     = string
    outbound_ip_count = number
  })

  default = {
    dns_service_ip    = "10.240.0.10"
    service_cidr      = "10.240.0.0/16"
    pod_cidr          = "10.244.0.0/16"
    outbound_type     = "loadBalancer"
    outbound_ip_count = 2
  }
}

# Upgrade settings
variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel for AKS cluster"
  type        = string
  default     = "patch"

  validation {
    condition     = contains(["none", "patch", "stable", "rapid", "node-image"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be none, patch, stable, rapid, or node-image."
  }
}

# Additional node pools
variable "additional_node_pools" {
  description = "Additional node pools for workloads"
  type = map(object({
    vm_size             = string
    os_sku              = string
    zones               = list(string)
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_count          = number
    max_pods            = number
    os_disk_size_gb     = number
    node_labels         = map(string)
    node_taints         = list(string)
    priority            = string # Regular or Spot
    eviction_policy     = string # Delete or Deallocate
    spot_max_price      = number
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
