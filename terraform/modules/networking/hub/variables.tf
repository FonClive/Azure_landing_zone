variable "vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for Gateway subnet"
  type        = list(string)
  default     = []
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for Firewall subnet"
  type        = list(string)
  default     = []
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for Bastion subnet"
  type        = list(string)
  default     = []
}

variable "shared_services_subnet_prefix" {
  description = "Address prefix for shared services subnet"
  type        = list(string)
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_firewall" {
  description = "Enable Azure Firewall"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable Azure Bastion"
  type        = bool
  default     = false
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
