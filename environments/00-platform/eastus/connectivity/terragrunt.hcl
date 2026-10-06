include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../terraform/modules/networking/hub"
}

dependency "resource_group" {
  config_path = "../resource-groups"
}

inputs = {
  vnet_name           = "vnet-platform-hub-eastus"
  location            = "eastus"
  resource_group_name = dependency.resource_group.outputs.resource_group_names["connectivity"]
  address_space       = ["10.0.0.0/16"]
  
  # Gateway subnet for VPN/ExpressRoute
  gateway_subnet_prefix         = ["10.0.0.0/27"]
  
  # Azure Firewall subnet
  firewall_subnet_prefix        = ["10.0.1.0/26"]
  
  # Azure Bastion subnet (optional)
  bastion_subnet_prefix         = ["10.0.2.0/27"]
  
  # Shared platform services
  shared_services_subnet_prefix = ["10.0.10.0/24"]
  
  # Feature flags
  enable_vpn_gateway = false
  enable_firewall    = true
  enable_bastion     = false
  firewall_sku_tier  = "Standard"
  
  tags = {
    Tier      = "Platform"
    Component = "Connectivity"
    Owner     = "PlatformTeam"
    Purpose   = "Hub network for all workload connectivity"
  }
}
