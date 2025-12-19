variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-dev-001"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-dev-001"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28.3"
}

variable "aks_admin_group_name" {
  description = "Azure AD group name for AKS administrators"
  type        = string
  default     = "AKS-Admins"
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server (CIDR)"
  type        = list(string)
  default     = [] # Empty for fully private, or add your IPs
}

variable "log_retention_days" {
  description = "Log Analytics retention period in days"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days for compliance."
  }
}
