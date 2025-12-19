# AKS Cluster Terraform Module

Enterprise-grade, security-hardened AKS cluster module implementing CIS Kubernetes Benchmark v1.8, DoD STIG v1r12, and NIST 800-190 controls.

## Features

### Security Hardening
- ✅ **CIS 5.1.1**: RBAC enabled with Azure AD integration
- ✅ **CIS 3.2.1**: Private cluster (no public API endpoint)
- ✅ **CIS 5.2.1**: Workload Identity (OIDC federation, no service principal keys)
- ✅ **CIS 5.4.1**: Azure Key Vault CSI Driver for secret management
- ✅ **CIS 5.1.4**: Comprehensive audit logging to Log Analytics
- ✅ **DoD STIG V-242376**: RBAC enforcement
- ✅ **DoD STIG V-242383**: Local accounts disabled
- ✅ **DoD STIG V-242414**: Azure Policy add-on enabled
- ✅ **DoD STIG V-242418**: API server access controls
- ✅ **DoD STIG V-242461**: Audit logging enabled
- ✅ **NIST 800-190**: Runtime threat detection with Microsoft Defender

### Infrastructure Configuration
- **Networking**: Azure CNI Overlay for IP efficiency
- **Identity**: User-assigned managed identities (no service principals)
- **Node Pools**: Separate system and workload node pools
- **OS**: Azure Linux (CBL-Mariner) hardened operating system
- **Storage**: Ephemeral OS disks for performance and security
- **Scaling**: Cluster autoscaler with optimized settings
- **Monitoring**: Log Analytics and Microsoft Defender integration
- **Maintenance**: Automated maintenance windows for updates

### Compliance
- CIS Kubernetes Benchmark v1.8
- DoD Kubernetes STIG v1r12
- NIST SP 800-190
- NSA Kubernetes Hardening Guide
- FedRAMP Moderate/High controls

## Usage

### Basic Example

```hcl
module "aks_cluster" {
  source = "../../modules/aks-cluster"

  cluster_name        = "aks-prod-001"
  resource_group_name = "rg-aks-prod"
  location            = "eastus"
  environment         = "prod"
  kubernetes_version  = "1.28.3"

  # Networking
  subnet_id         = azurerm_subnet.aks.id
  api_subnet_id     = azurerm_subnet.api.id

  # Security
  private_cluster_enabled = true
  disable_local_accounts  = true
  vnet_integration_enabled = true

  # Monitoring
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id

  # Azure AD
  tenant_id              = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids = ["12345678-1234-1234-1234-123456789012"]

  # SKU
  sku_tier = "Standard"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Example with Custom Node Pools

```hcl
module "aks_cluster" {
  source = "../../modules/aks-cluster"

  cluster_name        = "aks-prod-001"
  resource_group_name = "rg-aks-prod"
  location            = "eastus"
  environment         = "prod"

  # Custom system node pool
  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D8s_v5"
    os_sku              = "AzureLinux"
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 9
    node_count          = 3
    max_pods            = 30
    os_disk_size_gb     = 100
  }

  # Additional workload node pools
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D16s_v5"
      os_sku              = "AzureLinux"
      zones               = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count           = 3
      max_count           = 20
      node_count          = 3
      max_pods            = 50
      os_disk_size_gb     = 200
      node_labels = {
        workload = "general"
      }
      node_taints  = []
      priority     = "Regular"
      eviction_policy = "Delete"
      spot_max_price  = -1
    }

    compute = {
      vm_size             = "Standard_D32s_v5"
      os_sku              = "AzureLinux"
      zones               = ["1", "2", "3"]
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      node_count          = 0
      max_pods            = 30
      os_disk_size_gb     = 150
      node_labels = {
        workload = "compute-intensive"
      }
      node_taints = [
        "workload=compute:NoSchedule"
      ]
      priority     = "Spot"
      eviction_policy = "Delete"
      spot_max_price  = -1 # Pay up to regular price
    }
  }

  # Other configuration...
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| azurerm | ~> 3.85 |
| azuread | ~> 2.47 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the AKS cluster | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment (dev/staging/prod) | `string` | n/a | yes |
| subnet_id | Subnet ID for AKS nodes | `string` | n/a | yes |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | n/a | yes |
| tenant_id | Azure AD tenant ID | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.28.3"` | no |
| sku_tier | AKS SKU tier | `string` | `"Standard"` | no |
| private_cluster_enabled | Enable private cluster | `bool` | `true` | no |
| disable_local_accounts | Disable local accounts | `bool` | `true` | no |
| admin_group_object_ids | Azure AD admin group IDs | `list(string)` | `[]` | no |

See [variables.tf](./variables.tf) for complete list of inputs.

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | AKS cluster resource ID |
| cluster_name | AKS cluster name |
| cluster_fqdn | AKS cluster FQDN |
| oidc_issuer_url | OIDC issuer URL for workload identity |
| kubelet_identity | Kubelet managed identity details |
| cluster_identity | Cluster managed identity details |

See [outputs.tf](./outputs.tf) for complete list of outputs.

## Security Considerations

1. **Private Cluster**: The cluster API server is not exposed to the internet by default
2. **No Service Principals**: Uses workload identity (OIDC) instead of static credentials
3. **Audit Logging**: All control plane logs sent to Log Analytics
4. **Network Policies**: Azure Network Policy enabled for microsegmentation
5. **Runtime Protection**: Microsoft Defender for Containers enabled
6. **Secret Management**: Azure Key Vault CSI Driver for secure secret injection
7. **RBAC**: Azure AD integration with group-based access control
8. **Node Hardening**: Azure Linux OS with CIS-compliant sysctls

## Compliance Mapping

### CIS Kubernetes Benchmark v1.8
- 3.2.1: Private cluster enabled
- 5.1.1: RBAC with Azure AD
- 5.1.4: Audit logging enabled
- 5.1.5: Secure kubelet configuration
- 5.2.1: Workload identity (no secrets)
- 5.3.1: Network policies enabled
- 5.4.1: Secrets as files (Key Vault CSI)
- 5.7.1: Image cleaner enabled

### DoD STIG v1r12
- V-242376: RBAC enabled
- V-242381: Namespace separation
- V-242383: Local accounts disabled
- V-242414: Policy enforcement (Azure Policy)
- V-242418: API server protection
- V-242461: Audit logging

### NIST 800-190
- Section 4.1: Image security (Defender scanning)
- Section 4.4: Runtime defense (Defender for Containers)
- Section 5.1: Secure orchestration (hardened AKS)

## License

Apache 2.0
