# Enterprise-Grade Hardened AKS Cluster Terraform Module

Production-ready, security-hardened Azure Kubernetes Service (AKS) module implementing CIS Kubernetes Benchmark v1.8, DoD STIG v1r12, NIST 800-190, and FedRAMP controls.

## Overview

This Terraform module deploys a fully hardened AKS cluster with:

- **Security Hardening**: CIS Benchmark, DoD STIG, NIST 800-190 compliance
- **High Availability**: Multi-zone deployment with 99.9%+ SLA
- **Supply Chain Security**: Workload identity (OIDC), no service principals
- **Network Security**: Private cluster, UDR support, network policies
- **Monitoring**: Comprehensive logging, metrics, and alerting
- **Cost Optimization**: Multiple node pools with autoscaling

## Features

### Security Controls

- ✅ **Private Cluster**: No public API endpoint (CIS 3.2.1)
- ✅ **Azure AD Integration**: Managed RBAC with Azure AD groups (CIS 5.1.1)
- ✅ **No Local Accounts**: Force Azure AD authentication (DoD STIG V-242383)
- ✅ **Workload Identity**: OIDC federation, no service principal keys (CIS 5.2.1)
- ✅ **Network Policies**: Zero-trust microsegmentation (CIS 5.3.1)
- ✅ **Key Vault CSI**: Secrets as files, not environment variables (CIS 5.4.1)
- ✅ **Comprehensive Audit Logs**: All control plane logs to Log Analytics (CIS 5.1.4)
- ✅ **Azure Policy**: Policy-as-code enforcement (DoD STIG V-242414)
- ✅ **Microsoft Defender**: Runtime threat detection (NIST 800-190)

### Architecture Components

#### Compute

- **System Node Pool**: Dedicated for Kubernetes system components
  - Tainted with `CriticalAddonsOnly=true:NoSchedule`
  - Minimum 3 nodes across availability zones (HA)
  - Ephemeral OS disks for performance and security

- **General Workload Node Pool**: For general application workloads
  - Auto-scaling enabled
  - Zone-redundant deployment

- **GPU Node Pool** (optional): For ML/AI workloads
  - NVIDIA Tesla V100/A100 support
  - Scale-to-zero capability
  - Tainted to prevent non-GPU workloads

- **Memory-Optimized Pool** (optional): For data processing, caching
  - E-series VMs with high memory-to-CPU ratio

- **Compute-Optimized Pool** (optional): For CPU-intensive workloads
  - F-series VMs optimized for compute

#### Networking

- **Azure CNI Overlay**: IP address efficiency (requires AKS 1.22+)
- **Network Policy**: Azure Network Policy or Calico
- **Outbound Options**:
  - Load Balancer (default)
  - User Defined Routing (Azure Firewall)
  - NAT Gateway (cost-optimized alternative)

#### Identity & Access

- **Cluster Identity**: User-assigned managed identity
- **Kubelet Identity**: Separate identity for ACR authentication
- **Workload Identity**: OIDC federation for pod identities
- **Azure AD RBAC**: Group-based access control

#### Add-ons & Features

- **Azure Policy**: Enforce governance policies
- **Container Insights**: Azure Monitor for containers
- **Microsoft Defender**: Runtime threat detection
- **Key Vault CSI Driver**: Secure secret injection
- **Service Mesh** (optional): Istio integration
- **Image Cleaner**: Automatic removal of unused images

## Architecture Diagram Description

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Hub Virtual Network                      │  │
│  │  - Azure Firewall                                    │  │
│  │  - Azure Bastion                                     │  │
│  │  - Private DNS Zones                                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│                            │ VNet Peering                   │
│                            ▼                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         AKS Virtual Network (10.0.0.0/16)           │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────┐     │  │
│  │  │  System Node Pool Subnet (10.0.0.0/20)    │     │  │
│  │  │  - 3-9 nodes (Standard_D8s_v5)            │     │  │
│  │  │  - Zones: 1, 2, 3                         │     │  │
│  │  │  - Only system pods                        │     │  │
│  │  └────────────────────────────────────────────┘     │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────┐     │  │
│  │  │  General Workload Subnet (Same/Separate)   │     │  │
│  │  │  - 2-20 nodes (Standard_D16s_v5)          │     │  │
│  │  │  - Auto-scaling enabled                    │     │  │
│  │  └────────────────────────────────────────────┘     │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────┐     │  │
│  │  │  API Server Subnet (10.0.16.0/28)         │     │  │
│  │  │  - Private API endpoint                    │     │  │
│  │  │  - VNet integrated                         │     │  │
│  │  └────────────────────────────────────────────┘     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Azure Services                           │  │
│  │  - Azure Container Registry (ACR)                   │  │
│  │  - Azure Key Vault                                  │  │
│  │  - Log Analytics Workspace                          │  │
│  │  - Azure Monitor                                    │  │
│  │  - Microsoft Defender for Containers                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| azurerm | ~> 3.85 |
| azuread | ~> 2.47 |

### Azure Permissions Required

- **Contributor** or **Owner** on subscription
- **User Access Administrator** (for RBAC assignments)
- **Managed Identity Operator** (for workload identity)

## Usage

### Basic Example

```hcl
module "aks" {
  source = "../../modules/terraform/aks-cluster"

  # Core Configuration
  cluster_name        = "aks-prod-001"
  resource_group_name = "rg-aks-prod"
  location            = "eastus"
  environment         = "prod"
  kubernetes_version  = "1.28.3"
  sku_tier            = "Premium"

  # Networking
  aks_subnet_id              = azurerm_subnet.aks.id
  vnet_id                    = azurerm_virtual_network.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  # Azure AD Integration
  admin_group_object_ids = ["12345678-1234-1234-1234-123456789012"]

  # Security
  private_cluster_enabled = true
  disable_local_accounts  = true
  enable_azure_rbac       = true

  # Node Pools
  system_node_pool_vm_size = "Standard_D8s_v5"
  system_node_pool_min_count = 3
  system_node_pool_max_count = 9

  enable_general_node_pool = true
  general_node_pool_vm_size = "Standard_D16s_v5"
  general_node_pool_min_count = 2
  general_node_pool_max_count = 20

  # Tags
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Production Example with UDR and Azure Firewall

```hcl
module "aks" {
  source = "../../modules/terraform/aks-cluster"

  cluster_name        = "aks-prod-001"
  resource_group_name = "rg-aks-prod"
  location            = "eastus"
  environment         = "prod"

  # Networking with UDR
  aks_subnet_id              = azurerm_subnet.aks.id
  use_user_defined_routing   = true
  create_route_table         = true
  default_route_next_hop_ip  = azurerm_firewall.hub.ip_configuration[0].private_ip_address
  managed_outbound_ip_count  = 0

  # Private cluster with VNet integration
  private_cluster_enabled  = true
  enable_vnet_integration  = true
  api_server_subnet_id     = azurerm_subnet.api.id
  create_private_dns_zone  = true
  link_to_hub_vnet         = true
  hub_vnet_id              = azurerm_virtual_network.hub.id

  # Maximum security
  disable_local_accounts = true
  enable_run_command     = false

  # All node pools
  enable_general_node_pool           = true
  enable_gpu_node_pool               = true
  enable_memory_optimized_node_pool  = true
  enable_compute_optimized_node_pool = true

  # Service mesh
  enable_service_mesh = true
  service_mesh_mode   = "Istio"

  # Monitoring
  create_action_group  = true
  create_metric_alerts = true
  create_log_alerts    = true

  alert_email_receivers = [
    {
      name          = "Platform-Team"
      email_address = "platform-team@example.com"
    }
  ]
}
```

## Inputs

See [variables.tf](./variables.tf) for the complete list of input variables.

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| cluster_name | AKS cluster name | `string` |
| resource_group_name | Resource group name | `string` |
| location | Azure region | `string` |
| aks_subnet_id | Subnet ID for AKS nodes | `string` |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` |
| admin_group_object_ids | Azure AD admin group IDs | `list(string)` |

### Key Optional Inputs

| Name | Description | Default |
|------|-------------|---------|
| kubernetes_version | Kubernetes version | `"1.28.3"` |
| sku_tier | SKU tier (Standard/Premium) | `"Standard"` |
| private_cluster_enabled | Enable private cluster | `true` |
| disable_local_accounts | Disable local accounts | `true` |
| network_plugin | Network plugin | `"azure"` |
| enable_overlay_networking | Enable CNI Overlay | `true` |
| network_policy | Network policy plugin | `"azure"` |
| enable_general_node_pool | Enable general workload pool | `true` |
| enable_gpu_node_pool | Enable GPU pool | `false` |

## Outputs

See [outputs.tf](./outputs.tf) for the complete list of outputs.

### Key Outputs

| Name | Description |
|------|-------------|
| cluster_id | AKS cluster resource ID |
| cluster_name | Cluster name |
| oidc_issuer_url | OIDC issuer for workload identity |
| kubelet_identity | Kubelet identity for ACR pull |
| kube_config | Kubernetes config (sensitive) |
| compliance_summary | Compliance status summary |

## Compliance

### CIS Kubernetes Benchmark v1.8

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| 3.2.1 | API server not exposed | `private_cluster_enabled = true` |
| 5.1.1 | RBAC enabled | Azure AD RBAC integration |
| 5.1.4 | Audit logs enabled | Diagnostic settings to Log Analytics |
| 5.1.5 | Secure kubelet config | Hardened kubelet_config and linux_os_config |
| 5.2.1 | Minimize pod secrets access | Workload Identity (OIDC) |
| 5.3.1 | Network policies | Azure Network Policy or Calico |
| 5.4.1 | Secrets as files | Key Vault CSI Driver |

### DoD STIG v1r12

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| V-242376 | RBAC enabled | `role_based_access_control_enabled = true` |
| V-242383 | No local accounts | `local_account_disabled = true` |
| V-242414 | Policy enforcement | `azure_policy_enabled = true` |
| V-242418 | API server protection | Private cluster + authorized IP ranges |
| V-242461 | Audit logging | All control plane logs enabled |

### NIST 800-190

- **Section 4.1**: Image security (Microsoft Defender scanning)
- **Section 4.4**: Runtime defense (Microsoft Defender for Containers)
- **Section 5.1**: Secure orchestration (hardened AKS configuration)

### FedRAMP

- **99.9%+ SLA**: Standard or Premium SKU
- **High Availability**: 3+ nodes across availability zones
- **Audit Logging**: 365-day retention in Log Analytics
- **Encryption**: Azure encryption at rest and in transit

## Best Practices

### Production Deployment

1. **Use Premium SKU**: 99.95% SLA with longer support window
2. **Enable Private Cluster**: No public API endpoint
3. **Use UDR**: Route through Azure Firewall for traffic inspection
4. **Separate Node Pools**: Isolate workloads by requirements
5. **Enable Service Mesh**: For advanced traffic management and security
6. **Configure Alerts**: Monitor cluster health and performance
7. **Regular Upgrades**: Use automatic patch channel

### Security Hardening

1. **Disable Local Accounts**: Force Azure AD authentication
2. **Disable Run Command**: Prevent kubectl exec bypass
3. **Use Workload Identity**: No service principal keys
4. **Enable Network Policies**: Enforce zero-trust networking
5. **Enable Image Cleaner**: Remove unused images
6. **Configure Maintenance Windows**: Control update timing

### Cost Optimization

1. **Use Ephemeral Disks**: Lower cost and better performance
2. **Enable Autoscaling**: Right-size node pools
3. **Scale GPU to Zero**: When not in use
4. **Use Spot Instances**: For non-production GPU workloads
5. **Choose Right VM Sizes**: Don't over-provision

### High Availability

1. **Minimum 3 System Nodes**: Across availability zones
2. **Separate System and User Pools**: Isolate critical components
3. **Configure PDBs**: For application workloads
4. **Multi-Region**: For disaster recovery (deploy multiple clusters)

## Node Pool Sizing Guide

### System Pool

| Environment | VM Size | Min | Max | Use Case |
|-------------|---------|-----|-----|----------|
| Dev | Standard_D4s_v5 | 3 | 4 | Development |
| Prod | Standard_D8s_v5 | 3 | 9 | Production |

### General Workload Pool

| Environment | VM Size | Min | Max | Use Case |
|-------------|---------|-----|-----|----------|
| Dev | Standard_D8s_v5 | 2 | 10 | General apps |
| Prod | Standard_D16s_v5 | 3 | 50 | Production apps |

### GPU Pool

| Workload | VM Size | GPU | Use Case |
|----------|---------|-----|----------|
| Inference | Standard_NC6s_v3 | V100 | ML inference |
| Training | Standard_NC24s_v3 | 4x V100 | ML training |
| Large Models | Standard_ND40rs_v2 | 8x V100 | Large model training |

## Troubleshooting

### Common Issues

**Issue**: Cluster creation fails with "Subnet is not in same location"
**Solution**: Ensure subnet and cluster are in same Azure region

**Issue**: Cannot access private cluster API
**Solution**: Use Azure Bastion, VPN, or ExpressRoute. Or temporarily enable authorized IP ranges

**Issue**: Nodes not joining cluster
**Solution**: Check NSG rules, route tables, and network connectivity to Azure services

**Issue**: ACR pull fails
**Solution**: Verify kubelet identity has AcrPull role on ACR

## Examples

- [Development Environment](./examples/dev.tfvars)
- [Production Environment](./examples/prod.tfvars)

## Contributing

This module follows Terraform best practices and Azure Well-Architected Framework principles.

## License

Apache 2.0

## References

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [DoD Kubernetes STIG](https://public.cyber.mil/stigs/)
- [NIST 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)
- [Azure AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
