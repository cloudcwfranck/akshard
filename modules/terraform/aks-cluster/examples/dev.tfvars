# Development Environment Example Configuration
# Lower-cost configuration for development and testing

# Core Configuration
cluster_name        = "aks-dev-001"
resource_group_name = "rg-aks-dev"
location            = "eastus"
environment         = "dev"
kubernetes_version  = "1.28.3"
sku_tier            = "Standard" # 99.9% SLA

# Networking
aks_subnet_id              = "/subscriptions/<subscription-id>/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-aks-dev/subnets/snet-aks-nodes"
vnet_id                    = "/subscriptions/<subscription-id>/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-aks-dev"
log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/rg-monitoring/providers/Microsoft.OperationalInsights/workspaces/law-aks-dev"

# Azure AD Integration
admin_group_object_ids   = ["12345678-1234-1234-1234-123456789012"] # AKS-Dev-Admins
viewer_group_object_ids  = ["87654321-4321-4321-4321-210987654321"] # AKS-Dev-Viewers
developer_group_object_ids = ["11111111-2222-3333-4444-555555555555"] # Developers

# Security (relaxed for dev)
private_cluster_enabled             = false # Public endpoint for easier access in dev
disable_local_accounts              = true
api_server_authorized_ip_ranges     = ["0.0.0.0/0"] # Allow all (dev only)
enable_azure_rbac                   = true
grant_developer_access              = true

# Networking Mode
network_plugin           = "azure"
enable_overlay_networking = true
network_policy           = "azure"
use_user_defined_routing = false
enable_nat_gateway       = false

# System Node Pool (smaller for dev)
system_node_pool_vm_size     = "Standard_D4s_v5"
system_node_pool_min_count   = 3 # HA still required
system_node_pool_max_count   = 4
system_node_pool_max_pods    = 100
system_node_pool_os_disk_type = "Ephemeral"

# General Workload Node Pool
enable_general_node_pool        = true
general_node_pool_vm_size       = "Standard_D8s_v5"
general_node_pool_min_count     = 2
general_node_pool_max_count     = 10
general_node_pool_max_pods      = 100

# GPU Node Pool (disabled for dev to save cost)
enable_gpu_node_pool = false

# Memory-Optimized Node Pool (disabled for dev)
enable_memory_optimized_node_pool = false

# Compute-Optimized Node Pool (disabled for dev)
enable_compute_optimized_node_pool = false

# Automatic Upgrades
automatic_channel_upgrade = "patch"
node_os_channel_upgrade   = "NodeImage"

# Add-ons
enable_azure_policy        = true
enable_service_mesh        = false
enable_container_insights  = true
enable_image_cleaner       = true
image_cleaner_interval_hours = 48

# Monitoring and Alerts
create_action_group  = false
create_metric_alerts = false
create_log_alerts    = false

# ACR Integration (if you have ACR)
container_registry_id = "/subscriptions/<subscription-id>/resourceGroups/rg-acr/providers/Microsoft.ContainerRegistry/registries/acrdev001"

# Tagging
data_classification = "Internal"
cost_center         = "Engineering"
tags = {
  Environment = "Development"
  Owner       = "platform-team@example.com"
  Project     = "AKS-Platform"
  CostCenter  = "Engineering"
  Terraform   = "true"
}
