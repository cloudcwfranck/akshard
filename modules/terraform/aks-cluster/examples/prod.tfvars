# Production Environment Example Configuration
# Full security hardening for production workloads

# Core Configuration
cluster_name        = "aks-prod-001"
resource_group_name = "rg-aks-prod"
location            = "eastus"
environment         = "prod"
kubernetes_version  = "1.28.3"
sku_tier            = "Premium" # 99.95% SLA + longer support

# Networking
aks_subnet_id              = "/subscriptions/<subscription-id>/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-aks-prod/subnets/snet-aks-nodes"
vnet_id                    = "/subscriptions/<subscription-id>/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-aks-prod"
api_server_subnet_id       = "/subscriptions/<subscription-id>/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-aks-prod/subnets/snet-api-server"
log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/law-aks-prod"

# Azure AD Integration
admin_group_object_ids     = ["12345678-1234-1234-1234-123456789012"] # AKS-Prod-Admins
viewer_group_object_ids    = ["87654321-4321-4321-4321-210987654321"] # AKS-Prod-Viewers
developer_group_object_ids = [] # No direct developer access to prod

# Maximum Security Configuration
private_cluster_enabled             = true  # CIS 3.2.1 - No public endpoint
private_cluster_public_fqdn_enabled = false
disable_local_accounts              = true  # DoD STIG V-242383
api_server_authorized_ip_ranges     = []    # Private only, no public access
enable_azure_rbac                   = true
enable_vnet_integration             = true
grant_kubernetes_cluster_admin      = true
grant_developer_access              = false # No developer access in prod
enable_run_command                  = false # Disabled for security

# Networking Mode with UDR (Azure Firewall)
network_plugin            = "azure"
enable_overlay_networking = true
network_policy            = "azure"
use_user_defined_routing  = true # Force through Azure Firewall
enable_nat_gateway        = false # Using Azure Firewall instead
managed_outbound_ip_count = 0

# UDR Configuration
create_route_table             = false # Managed separately
default_route_next_hop_ip      = "10.100.0.4" # Azure Firewall IP
create_nsg                     = false # Managed separately
create_private_dns_zone        = false # Managed separately
private_dns_zone_id            = "/subscriptions/<subscription-id>/resourceGroups/rg-network-prod/providers/Microsoft.Network/privateDnsZones/privatelink.eastus.azmk8s.io"
link_to_hub_vnet               = true
hub_vnet_id                    = "/subscriptions/<subscription-id>/resourceGroups/rg-network-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"

# System Node Pool (production-sized)
system_node_pool_vm_size       = "Standard_D8s_v5" # 8 vCPU, 32GB RAM
system_node_pool_min_count     = 3
system_node_pool_max_count     = 9
system_node_pool_max_pods      = 100
system_node_pool_os_disk_size  = 128
system_node_pool_os_disk_type  = "Ephemeral"

# General Workload Node Pool
enable_general_node_pool        = true
general_node_pool_vm_size       = "Standard_D16s_v5" # 16 vCPU, 64GB RAM
general_node_pool_min_count     = 3
general_node_pool_max_count     = 50
general_node_pool_max_pods      = 100
general_node_pool_os_disk_type  = "Ephemeral"

# GPU Node Pool (for ML/AI workloads)
enable_gpu_node_pool            = true
gpu_node_pool_vm_size           = "Standard_NC6s_v3" # Tesla V100
gpu_node_pool_min_count         = 0 # Scale to zero when not in use
gpu_node_pool_max_count         = 10
gpu_node_pool_max_pods          = 30
gpu_node_pool_priority          = "Regular" # Production: use Regular, not Spot
gpu_accelerator_type            = "nvidia-tesla-v100"

# Memory-Optimized Node Pool (for data processing)
enable_memory_optimized_node_pool        = true
memory_optimized_node_pool_vm_size       = "Standard_E16s_v5" # 16 vCPU, 128GB RAM
memory_optimized_node_pool_min_count     = 0
memory_optimized_node_pool_max_count     = 20
memory_optimized_node_pool_os_disk_type  = "Ephemeral"

# Compute-Optimized Node Pool (for CPU-intensive workloads)
enable_compute_optimized_node_pool       = true
compute_optimized_node_pool_vm_size      = "Standard_F16s_v2" # 16 vCPU
compute_optimized_node_pool_min_count    = 0
compute_optimized_node_pool_max_count    = 20

# Automatic Upgrades (conservative for production)
automatic_channel_upgrade = "patch" # Only patch updates
node_os_channel_upgrade   = "SecurityPatch" # Only security patches

# Maintenance Windows (Sunday early morning)
maintenance_window_day             = "Sunday"
maintenance_window_hours           = [0, 1, 2, 3, 4, 5]
maintenance_window_start_time      = "00:00"
maintenance_window_node_os_start_time = "04:00"
maintenance_window_utc_offset      = "-05:00" # EST
# Block maintenance during critical periods (e.g., Black Friday, tax season)
maintenance_window_not_allowed_start = "2024-11-20"
maintenance_window_not_allowed_end   = "2024-11-30"

# Add-ons
enable_azure_policy        = true
enable_service_mesh        = true
service_mesh_mode          = "Istio"
service_mesh_internal_ingress_enabled = true
service_mesh_external_ingress_enabled = false
enable_container_insights  = true
enable_image_cleaner       = true
image_cleaner_interval_hours = 72
enable_secret_rotation     = true
secret_rotation_interval   = "2m"

# RBAC Configuration
enable_workload_identity_rbac     = true
grant_vm_contributor_role         = true
grant_private_dns_contributor     = true

# Monitoring and Alerting
create_action_group               = true
create_metric_alerts              = true
create_log_alerts                 = true
node_cpu_alert_threshold          = 80
node_memory_alert_threshold       = 85
pod_count_alert_threshold         = 5000

alert_email_receivers = [
  {
    name          = "Platform-Team"
    email_address = "platform-team@example.com"
  },
  {
    name          = "On-Call"
    email_address = "oncall@example.com"
  }
]

alert_webhook_receivers = [
  {
    name        = "PagerDuty"
    service_uri = "https://events.pagerduty.com/integration/<integration-key>/enqueue"
  }
]

# Storage for diagnostic logs (365 days retention for compliance)
diagnostic_storage_account_id = "/subscriptions/<subscription-id>/resourceGroups/rg-monitoring-prod/providers/Microsoft.Storage/storageAccounts/stdiagprod"

# ACR Integration
container_registry_id = "/subscriptions/<subscription-id>/resourceGroups/rg-acr-prod/providers/Microsoft.ContainerRegistry/registries/acrprod001"

# Key Vault Integration
key_vault_id = "/subscriptions/<subscription-id>/resourceGroups/rg-keyvault-prod/providers/Microsoft.KeyVault/vaults/kv-aks-prod"

# DDoS Protection (optional, expensive but recommended for production)
enable_ddos_protection = true

# Tagging
data_classification = "Confidential"
cost_center         = "Production-Infrastructure"
tags = {
  Environment         = "Production"
  Owner               = "platform-team@example.com"
  Project             = "AKS-Platform"
  CostCenter          = "Production-Infrastructure"
  DataClassification  = "Confidential"
  BusinessUnit        = "Technology"
  Compliance          = "CIS-v1.8-DoD-STIG-v1r12-FedRAMP"
  DisasterRecovery    = "Critical"
  BackupPolicy        = "Daily"
  Terraform           = "true"
}
