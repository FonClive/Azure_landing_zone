# Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  
  tags = var.tags
}

# Subnets
resource "azurerm_subnet" "workload" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = each.value.address_prefixes
  
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "workload" {
  for_each            = var.subnets
  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.workload[each.key].id
  network_security_group_id = azurerm_network_security_group.workload[each.key].id
}

# VNet Peering to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${var.vnet_name}-to-hub"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateway
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-${var.vnet_name}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.hub_allow_gateway_transit
  use_remote_gateways          = false
}

# Route Table
resource "azurerm_route_table" "spoke" {
  count                         = var.route_to_firewall ? 1 : 0
  name                          = "rt-${var.vnet_name}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = false
  
  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip
  }
  
  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "spoke" {
  for_each       = var.route_to_firewall ? var.subnets : {}
  subnet_id      = azurerm_subnet.workload[each.key].id
  route_table_id = azurerm_route_table.spoke[0].id
}
