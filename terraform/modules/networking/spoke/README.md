# Spoke Network Module

## Overview

This module creates a spoke virtual network that peers with a hub network following the hub-spoke topology pattern. Spoke networks host workload-specific resources and route traffic through the hub's Azure Firewall for centralized security.

## Features

- ✅ Spoke Virtual Network with customizable address space
- ✅ Multiple subnets with configurable address prefixes
- ✅ Network Security Groups per subnet
- ✅ VNet peering to hub (bidirectional)
- ✅ Route tables for traffic routing through firewall
- ✅ Support for subnet delegation (e.g., for containers)
- ✅ Optional use of hub's VPN gateway

## Architecture

```
Hub VNet (10.0.0.0/16)
        │
        │ VNet Peering
        ▼
Spoke VNet (10.1.0.0/16)
├── snet-app (10.1.1.0/24)          [Application tier]
├── snet-data (10.1.2.0/24)         [Database tier]
├── snet-integration (10.1.3.0/24)  [Integration services]
└── snet-containers (10.1.4.0/24)   [Container instances]
        │
        │ UDR: 0.0.0.0/0 → Firewall
        ▼
Azure Firewall (Hub)
```

## Usage

### Basic Example

```hcl
module "spoke_network" {
  source = "../../modules/networking/spoke"

  vnet_name           = "vnet-dev-eastus"
  location            = "eastus"
  resource_group_name = "rg-dev-networking-eastus"
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    "snet-app" = {
      address_prefixes = ["10.1.1.0/24"]
    }
    "snet-data" = {
      address_prefixes = ["10.1.2.0/24"]
    }
  }
  
  # Hub connectivity
  hub_vnet_id             = module.hub_network.vnet_id
  hub_vnet_name           = module.hub_network.vnet_name
  hub_resource_group_name = "rg-platform-connectivity-eastus"
  firewall_private_ip     = module.hub_network.firewall_private_ip
  route_to_firewall       = true
  
  tags = {
    Environment = "Development"
    Tier        = "Workload"
  }
}
```

### Complete Example with Delegated Subnets

```hcl
module "spoke_network" {
  source = "../../modules/networking/spoke"

  vnet_name           = "vnet-prod-eastus"
  location            = "eastus"
  resource_group_name = "rg-prod-networking-eastus"
  address_space       = ["10.2.0.0/16"]
  
  subnets = {
    "snet-app" = {
      address_prefixes = ["10.2.1.0/24"]
    }
    "snet-data" = {
      address_prefixes = ["10.2.2.0/24"]
    }
    "snet-integration" = {
      address_prefixes = ["10.2.3.0/24"]
    }
    "snet-containers" = {
      address_prefixes = ["10.2.4.0/24"]
      delegation = {
        name         = "aci-delegation"
        service_name = "Microsoft.ContainerInstance/containerGroups"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "snet-webapp" = {
      address_prefixes = ["10.2.5.0/24"]
      delegation = {
        name         = "webapp-delegation"
        service_name = "Microsoft.Web/serverFarms"
        actions      = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }
  }
  
  # Hub connectivity
  hub_vnet_id              = module.hub_network.vnet_id
  hub_vnet_name            = module.hub_network.vnet_name
  hub_resource_group_name  = "rg-platform-connectivity-eastus"
  use_remote_gateway       = true   # Use hub's VPN gateway
  hub_allow_gateway_transit = true
  route_to_firewall        = true
  firewall_private_ip      = module.hub_network.firewall_private_ip
  
  tags = {
    Environment = "Production"
    Tier        = "Workload"
    Component   = "Networking"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.80.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vnet_name | Name of the spoke virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| address_space | Address space for the spoke VNet | `list(string)` | n/a | yes |
| subnets | Map of subnets to create | `map(object)` | n/a | yes |
| hub_vnet_id | Hub VNet ID for peering | `string` | n/a | yes |
| hub_vnet_name | Hub VNet name for peering | `string` | n/a | yes |
| hub_resource_group_name | Hub resource group name | `string` | n/a | yes |
| use_remote_gateway | Use hub VPN gateway | `bool` | `false` | no |
| hub_allow_gateway_transit | Allow gateway transit from hub | `bool` | `true` | no |
| route_to_firewall | Route traffic through Azure Firewall | `bool` | `true` | no |
| firewall_private_ip | Private IP of Azure Firewall | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Subnets Object Structure

```hcl
subnets = {
  "subnet-name" = {
    address_prefixes = ["10.1.1.0/24"]
    delegation = optional({                    # Optional subnet delegation
      name         = string
      service_name = string
      actions      = list(string)
    })
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Spoke VNet ID |
| vnet_name | Spoke VNet name |
| subnet_ids | Map of subnet IDs indexed by subnet name |

## Subnet Delegation Examples

### Container Instances (ACI)
```hcl
delegation = {
  name         = "aci-delegation"
  service_name = "Microsoft.ContainerInstance/containerGroups"
  actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
}
```

### App Service (Web Apps)
```hcl
delegation = {
  name         = "webapp-delegation"
  service_name = "Microsoft.Web/serverFarms"
  actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
}
```

### Azure Kubernetes Service (AKS)
```hcl
delegation = {
  name         = "aks-delegation"
  service_name = "Microsoft.ContainerService/managedClusters"
  actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
}
```

### Azure SQL Managed Instance
```hcl
delegation = {
  name         = "sqlmi-delegation"
  service_name = "Microsoft.Sql/managedInstances"
  actions      = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
  ]
}
```

## VNet Peering

The module automatically creates bidirectional peering:

### Spoke → Hub Peering
- **allow_virtual_network_access**: True
- **allow_forwarded_traffic**: True (to receive traffic from other spokes)
- **allow_gateway_transit**: False
- **use_remote_gateways**: Configurable (set to true to use hub VPN)

### Hub → Spoke Peering
- **allow_virtual_network_access**: True
- **allow_forwarded_traffic**: True (to forward traffic between spokes)
- **allow_gateway_transit**: Configurable (set to true if hub has VPN)
- **use_remote_gateways**: False

## Route Tables

When `route_to_firewall = true`, a route table is created with:

| Destination | Next Hop | Purpose |
|-------------|----------|---------|
| 0.0.0.0/0 | Azure Firewall | Force all internet traffic through firewall |

Additional routes can be added:

```hcl
resource "azurerm_route" "to_on_prem" {
  name                   = "to-on-prem"
  resource_group_name    = var.resource_group_name
  route_table_name       = module.spoke_network.route_table_name
  address_prefix         = "192.168.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}
```

## Network Security Groups

The module creates one NSG per subnet. Add custom rules:

```hcl
# Allow HTTPS from internet
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = "nsg-snet-app"
}

# Allow SQL from app subnet
resource "azurerm_network_security_rule" "allow_sql" {
  name                        = "AllowSQLFromApp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "10.1.1.0/24"  # App subnet
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = "nsg-snet-data"
}
```

## Address Space Planning

### Recommended Spoke Sizes

| Environment | VNet CIDR | Usable IPs | Use Case |
|-------------|-----------|------------|----------|
| Dev/Test | /20 (10.x.0.0/20) | ~4000 | Development environments |
| Production | /16 (10.x.0.0/16) | ~65000 | Large production workloads |
| Small App | /24 (10.x.0.0/24) | ~250 | Single small application |

### Example Address Plan

```
Spoke: 10.1.0.0/16 (Dev)
├── snet-app:          10.1.1.0/24   (256 IPs)
├── snet-data:         10.1.2.0/24   (256 IPs)
├── snet-integration:  10.1.3.0/24   (256 IPs)
├── snet-containers:   10.1.4.0/24   (256 IPs)
└── Reserved:          10.1.5.0 - 10.1.255.255
```

## Traffic Flow

### Outbound Internet Traffic
```
VM in Spoke → Route Table → Firewall (Hub) → Internet
```

### Spoke-to-Spoke Traffic
```
Spoke A → Firewall (Hub) → Spoke B
```

### Spoke-to-On-Premises
```
Spoke → Firewall → VPN Gateway (Hub) → On-Premises
```

## Dependencies

The spoke module requires the hub module to be deployed first:

```hcl
# Deploy hub first
module "hub_network" {
  source = "../../modules/networking/hub"
  # ...
}

# Then deploy spoke
module "spoke_network" {
  source = "../../modules/networking/spoke"
  
  # Reference hub outputs
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  firewall_private_ip = module.hub_network.firewall_private_ip
  # ...
}
```

## Multiple Spokes Example

```hcl
# Dev Spoke
module "spoke_dev" {
  source = "../../modules/networking/spoke"
  
  vnet_name     = "vnet-dev-eastus"
  address_space = ["10.1.0.0/16"]
  # ... hub references ...
}

# Test Spoke
module "spoke_test" {
  source = "../../modules/networking/spoke"
  
  vnet_name     = "vnet-test-eastus"
  address_space = ["10.3.0.0/16"]
  # ... hub references ...
}

# Prod Spoke
module "spoke_prod" {
  source = "../../modules/networking/spoke"
  
  vnet_name     = "vnet-prod-eastus"
  address_space = ["10.2.0.0/16"]
  # ... hub references ...
}
```

## Best Practices

1. **Address Planning**: Reserve enough space for future subnets
2. **Subnet Sizing**: Use /24 or /25 for most application subnets
3. **NSG Rules**: Start restrictive, add specific allows
4. **Route Tables**: Always route through firewall for security
5. **Delegation**: Only delegate subnets when required by service
6. **Naming**: Use descriptive subnet names (snet-app, snet-data)

## Security Considerations

1. **Defense in Depth**: Use both NSGs and firewall rules
2. **Least Privilege**: Only open ports required for functionality
3. **Segmentation**: Use separate subnets for different tiers (app, data)
4. **Private Endpoints**: Use for Azure PaaS services instead of public endpoints
5. **Service Endpoints**: Enable for services that support them

## Cost Optimization

| Resource | Cost Factor | Optimization |
|----------|-------------|--------------|
| VNet Peering | Data transfer | Minimize cross-region traffic |
| Route Tables | Free | No cost impact |
| NSGs | Free | No cost impact |
| VNet | Free | No cost for VNet itself |

## Troubleshooting

### Cannot reach resources in spoke

1. Check NSG rules allow traffic
2. Verify route table points to firewall
3. Check firewall rules allow the traffic
4. Verify VNet peering is active

### VNet peering failed

1. Ensure hub VNet exists
2. Check RBAC permissions
3. Verify no overlapping address spaces
4. Check that `use_remote_gateway` is false if hub has no gateway

### Route not working

1. Verify firewall private IP is correct
2. Check route table is associated with subnet
3. Ensure `route_to_firewall = true`

## Common NSG Rule Patterns

### Three-Tier Application

```hcl
# Web Tier (snet-app)
- Allow: 443 from Internet
- Allow: 8080 from Load Balancer
- Deny: All other inbound

# App Tier (snet-integration)
- Allow: 8080 from snet-app
- Deny: All other inbound

# Data Tier (snet-data)
- Allow: 1433 from snet-integration
- Deny: All other inbound
```

## Related Modules

- **networking/hub** - Hub network that spokes peer to
- **resource-group** - Creates resource groups for spoke resources

## References

- [Hub-Spoke Topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [VNet Peering](https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview)
- [User Defined Routes](https://docs.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
- [NSGs](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Subnet Delegation](https://docs.microsoft.com/azure/virtual-network/subnet-delegation-overview)

## Changelog

### Version 1.1.0
- Added support for subnet delegation
- Added per-subnet NSG support
- Made route table optional

### Version 1.0.0
- Initial release with spoke VNet, subnets, peering, and routing
