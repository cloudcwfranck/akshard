variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# AKS Subnet
variable "aks_subnet_name" {
  description = "Name of the AKS nodes subnet"
  type        = string
  default     = "snet-aks-nodes"
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for AKS nodes subnet"
  type        = list(string)
  default     = ["10.0.0.0/20"]
}

# API Server Subnet
variable "enable_api_server_vnet_integration" {
  description = "Enable API server VNet integration"
  type        = bool
  default     = false
}

variable "api_subnet_name" {
  description = "Name of the API server subnet"
  type        = string
  default     = "snet-aks-api"
}

variable "api_subnet_address_prefixes" {
  description = "Address prefixes for API server subnet"
  type        = list(string)
  default     = ["10.0.16.0/28"]
}

# Application Gateway
variable "enable_application_gateway" {
  description = "Enable Application Gateway subnet"
  type        = bool
  default     = false
}

variable "appgw_subnet_name" {
  description = "Name of the Application Gateway subnet"
  type        = string
  default     = "snet-appgw"
}

variable "appgw_subnet_address_prefixes" {
  description = "Address prefixes for Application Gateway subnet"
  type        = list(string)
  default     = ["10.0.32.0/24"]
}

# Bastion
variable "enable_bastion" {
  description = "Enable Azure Bastion for secure management access"
  type        = bool
  default     = false
}

variable "bastion_subnet_address_prefixes" {
  description = "Address prefixes for Bastion subnet"
  type        = list(string)
  default     = ["10.0.64.0/26"]
}

# Private Endpoints
variable "enable_private_endpoints" {
  description = "Enable private endpoints subnet"
  type        = bool
  default     = true
}

variable "private_endpoints_subnet_name" {
  description = "Name of the private endpoints subnet"
  type        = string
  default     = "snet-private-endpoints"
}

variable "private_endpoints_subnet_address_prefixes" {
  description = "Address prefixes for private endpoints subnet"
  type        = list(string)
  default     = ["10.0.128.0/24"]
}

# NAT Gateway
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for outbound connectivity"
  type        = bool
  default     = false
}

variable "nat_gateway_zones" {
  description = "Availability zones for NAT Gateway"
  type        = list(string)
  default     = ["1"]
}

# Custom Route Table
variable "enable_custom_route_table" {
  description = "Enable custom route table for AKS subnet"
  type        = bool
  default     = false
}

# DDoS Protection
variable "enable_ddos_protection" {
  description = "Enable DDoS protection plan"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
