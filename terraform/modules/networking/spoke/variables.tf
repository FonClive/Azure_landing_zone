variable "vnet_name" {
  description = "Name of the spoke virtual network"
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
  description = "Address space for the spoke VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes = list(string)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
}

variable "hub_vnet_id" {
  description = "Hub VNet ID for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Hub VNet name for peering"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Hub resource group name"
  type        = string
}

variable "use_remote_gateway" {
  description = "Use hub VPN gateway"
  type        = bool
  default     = false
}

variable "hub_allow_gateway_transit" {
  description = "Allow gateway transit from hub"
  type        = bool
  default     = true
}

variable "route_to_firewall" {
  description = "Route traffic through Azure Firewall"
  type        = bool
  default     = true
}

variable "firewall_private_ip" {
  description = "Private IP of Azure Firewall"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
