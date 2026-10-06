include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../terraform/modules/networking/spoke"
}

dependency "resource_group" {
  config_path = "../resource-groups"
}

dependency "platform_rg" {
  config_path = "../../../../00-platform/eastus/resource-groups"
}

dependency "hub" {
  config_path = "../../../../00-platform/eastus/connectivity"
}

inputs = {
  vnet_name           = "vnet-dev-eastus"
  location            = "eastus"
  resource_group_name = dependency.resource_group.outputs.resource_group_names["networking"]
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    "snet-app" = {
      address_prefixes = ["10.1.1.0/24"]
    }
    "snet-data" = {
      address_prefixes = ["10.1.2.0/24"]
    }
    "snet-integration" = {
      address_prefixes = ["10.1.3.0/24"]
    }
    "snet-containers" = {
      address_prefixes = ["10.1.4.0/24"]
      delegation = {
        name         = "aci-delegation"
        service_name = "Microsoft.ContainerInstance/containerGroups"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
  
  # Connect to platform hub
  hub_vnet_id              = dependency.hub.outputs.vnet_id
  hub_vnet_name            = dependency.hub.outputs.vnet_name
  hub_resource_group_name  = dependency.platform_rg.outputs.resource_group_names["connectivity"]
  use_remote_gateway       = false
  hub_allow_gateway_transit = true
  route_to_firewall        = true
  firewall_private_ip      = dependency.hub.outputs.firewall_private_ip
  
  tags = {
    Environment = "Development"
    Tier        = "Workload"
    Component   = "Networking"
    Owner       = "DevTeam"
  }
}
