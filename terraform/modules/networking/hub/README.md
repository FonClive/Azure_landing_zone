# Hub Network Module

## Overview

This module creates a hub virtual network following the hub-spoke topology pattern. The hub serves as the central connectivity point for all spoke networks and typically includes shared services like Azure Firewall, VPN Gateway, and Azure Bastion.

## Features

- ✅ Hub Virtual Network with customizable address space
- ✅ Azure Firewall (Standard or Premium SKU)
- ✅ VPN Gateway subnet (optional)
- ✅ Azure Bastion subnet (optional)
- ✅ Shared services subnet for jump boxes, domain controllers, etc.
- ✅ Network Security Groups
- ✅ Automatic firewall public IP creation

## Architecture

```
Hub VNet (10.0.0.0/16)
├── GatewaySubnet (10.0.0.0/27)          [VPN/ExpressRoute]
├── AzureFirewallSubnet (10.0.1.0/26)   [Firewall]
├── AzureBastionSubnet (10.0.2.0/27)    [Bastion - Optional]
└── snet-shared-services (10.0.10.0/24)  [Jump boxes, etc.]
```

## Usage

### Basic Example

```hcl
module "hub_network" {
  source = "../../modules/networking/hub"

  vnet_name           = "vnet-platform-hub-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-connectivity-eastus"
  address_space       = ["10.0.0.0/16"]
  
  shared_services_subnet_prefix = ["10.0.10.0/24"]
  
  enable_firewall = true
  enable_vpn_gateway = false
  enable_bastion = false
  
  tags = {
    Tier = "Platform"
    Component = "Connectivity"
  }
}
```

### Complete Example with All Features

```hcl
module "hub_network" {
  source = "../../modules/networking/hub"

  vnet_name           = "vnet-platform-hub-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-connectivity-eastus"
  address_space       = ["10.0.0.0/16"]
  
  # Subnet configurations
  gateway_subnet_prefix         = ["10.0.0.0/27"]
  firewall_subnet_prefix        = ["10.0.1.0/26"]
  bastion_subnet_prefix         = ["10.0.2.0/27"]
  shared_services_subnet_prefix = ["10.0.10.0/24"]
  
  # Feature flags
  enable_vpn_gateway = true
  enable_firewall    = true
  enable_bastion     = true
  
  # Firewall configuration
  firewall_sku_tier = "Premium"  # or "Standard"
  
  tags = {
    Tier        = "Platform"
    Component   = "Connectivity"
    Environment = "Production"
    ManagedBy   = "Terraform"
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
| vnet_name | Name of the hub virtual network | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| address_space | Address space for the hub VNet | `list(string)` | n/a | yes |
| gateway_subnet_prefix | Address prefix for Gateway subnet | `list(string)` | `[]` | no |
| firewall_subnet_prefix | Address prefix for Firewall subnet | `list(string)` | `[]` | no |
| bastion_subnet_prefix | Address prefix for Bastion subnet | `list(string)` | `[]` | no |
| shared_services_subnet_prefix | Address prefix for shared services | `list(string)` | n/a | yes |
| enable_vpn_gateway | Enable VPN Gateway subnet | `bool` | `false` | no |
| enable_firewall | Enable Azure Firewall | `bool` | `true` | no |
| enable_bastion | Enable Azure Bastion subnet | `bool` | `false` | no |
| firewall_sku_tier | SKU tier for Azure Firewall | `string` | `"Standard"` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Hub VNet ID |
| vnet_name | Hub VNet name |
| firewall_private_ip | Private IP of Azure Firewall (null if disabled) |
| shared_services_subnet_id | Shared services subnet ID |

## Subnet Sizing Guide

| Subnet | Minimum Size | Recommended Size | Purpose |
|--------|--------------|------------------|---------|
| GatewaySubnet | /29 (8 IPs) | /27 (32 IPs) | VPN/ExpressRoute Gateway |
| AzureFirewallSubnet | /26 (64 IPs) | /26 (64 IPs) | Azure Firewall (required) |
| AzureBastionSubnet | /27 (32 IPs) | /26 (64 IPs) | Azure Bastion |
| Shared Services | /27 (32 IPs) | /24 (256 IPs) | Jump boxes, DCs, etc. |

## Azure Firewall SKU Comparison

| Feature | Standard | Premium |
|---------|----------|---------|
| Network/Application Rules | ✅ | ✅ |
| Threat Intelligence | ✅ | ✅ |
| TLS Inspection | ❌ | ✅ |
| IDPS | ❌ | ✅ |
| URL Filtering | ❌ | ✅ |
| Web Categories | ❌ | ✅ |
| Cost | Lower | Higher |

**Recommendation**: Use Standard for most workloads, Premium for high-security requirements.

## Network Security Groups

The module automatically creates NSG for shared services subnet:

```hcl
# Example NSG rule to add
resource "azurerm_network_security_rule" "allow_rdp" {
  name                        = "AllowRDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = module.hub_network.shared_services_nsg_name
}
```

## Firewall Configuration

After deployment, configure firewall rules:

### Network Rules
```bash
# Allow outbound HTTPS
az network firewall network-rule create \
  --collection-name "AllowWeb" \
  --destination-ports 443 \
  --firewall-name "afw-vnet-hub-eastus" \
  --name "AllowHTTPS" \
  --protocols TCP \
  --resource-group "rg-platform-connectivity-eastus" \
  --source-addresses "10.1.0.0/16" "10.2.0.0/16" \
  --destination-addresses "*" \
  --action Allow \
  --priority 100
```

### Application Rules
```bash
# Allow specific FQDNs
az network firewall application-rule create \
  --collection-name "AllowAzure" \
  --firewall-name "afw-vnet-hub-eastus" \
  --name "AllowAzureServices" \
  --protocols https=443 \
  --resource-group "rg-platform-connectivity-eastus" \
  --source-addresses "10.1.0.0/16" "10.2.0.0/16" \
  --target-fqdns "*.azure.com" "*.microsoft.com" \
  --priority 100 \
  --action Allow
```

## Address Space Planning

### Recommended Hub Sizes

| Scenario | VNet CIDR | Usable IPs | Use Case |
|----------|-----------|------------|----------|
| Small | /22 (10.0.0.0/22) | ~1000 | Single region, few spokes |
| Medium | /20 (10.0.0.0/20) | ~4000 | Multiple regions |
| Large | /16 (10.0.0.0/16) | ~65000 | Enterprise, many regions |

### Example Address Plan

```
Hub: 10.0.0.0/16
├── Gateway Subnet:       10.0.0.0/27   (32 IPs)
├── Firewall Subnet:      10.0.1.0/26   (64 IPs)
├── Bastion Subnet:       10.0.2.0/27   (32 IPs)
├── Shared Services:      10.0.10.0/24  (256 IPs)
└── Reserved for Growth:  10.0.11.0 - 10.0.255.255
```

## VPN Gateway Considerations

If `enable_vpn_gateway = true`:

1. **Gateway Subnet**: Reserved for VPN/ExpressRoute Gateway
2. **Gateway SKU**: Deploy separately after hub creation
3. **Connectivity**: For on-premises or site-to-site VPN

```hcl
# Deploy VPN Gateway after hub
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "vng-hub-eastus"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  type     = "Vpn"
  vpn_type = "RouteBased"
  
  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
  
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.hub_network.gateway_subnet_id
  }
}
```

## Bastion Configuration

If `enable_bastion = true`:

```hcl
# Deploy Azure Bastion after hub
resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub-eastus"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.hub_network.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
```

## Connecting Spokes

Spoke networks connect to hub via VNet peering:

```hcl
module "spoke" {
  source = "../../modules/networking/spoke"
  
  # Spoke configuration
  vnet_name = "vnet-dev-eastus"
  # ...
  
  # Hub connectivity
  hub_vnet_id              = module.hub_network.vnet_id
  hub_vnet_name            = module.hub_network.vnet_name
  firewall_private_ip      = module.hub_network.firewall_private_ip
  route_to_firewall        = true
  use_remote_gateway       = true  # Use hub VPN gateway
  hub_allow_gateway_transit = true
}
```

## Best Practices

1. **Address Space**: Reserve large enough space for future growth
2. **Firewall**: Always enable for production environments
3. **Bastion**: Use for secure RDP/SSH access instead of public IPs
4. **Gateway**: Plan for VPN/ExpressRoute needs upfront
5. **Monitoring**: Enable diagnostic settings on all resources
6. **High Availability**: Firewall is zone-redundant by default in supported regions

## Cost Optimization

| Resource | Cost Factor | Optimization |
|----------|-------------|--------------|
| Azure Firewall | Always running | Consider Basic SKU or stop in non-prod |
| VPN Gateway | Gateway SKU | Right-size based on throughput needs |
| Bastion | Hourly charge | Use only in environments requiring it |
| Public IPs | Per IP + data | Minimize number of public IPs |

### Cost Example (East US, Standard Firewall)
- Azure Firewall Standard: ~$800/month
- VPN Gateway (VpnGw1): ~$140/month
- Azure Bastion: ~$140/month
- Public IPs (3): ~$12/month

## Security Considerations

1. **Firewall Rules**: Start with deny-all, add specific allows
2. **NSGs**: Apply to all subnets for defense in depth
3. **Private Connectivity**: Prefer VPN/ExpressRoute over public internet
4. **Diagnostic Logs**: Send to Log Analytics for monitoring
5. **Threat Intelligence**: Enable on Azure Firewall

## Diagnostic Settings

Enable after deployment:

```bash
az monitor diagnostic-settings create \
  --name "firewall-diagnostics" \
  --resource /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/azureFirewalls/{name} \
  --workspace /subscriptions/{sub-id}/resourcegroups/{rg}/providers/microsoft.operationalinsights/workspaces/{law} \
  --logs '[{"category":"AzureFirewallApplicationRule","enabled":true},{"category":"AzureFirewallNetworkRule","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

## Troubleshooting

### Firewall not forwarding traffic

1. Check firewall rules exist
2. Verify spoke route tables point to firewall
3. Check firewall diagnostic logs

### Cannot deploy - subnet size too small

Adjust subnet prefixes to meet minimum requirements:
- Firewall: /26 minimum
- Gateway: /27 minimum
- Bastion: /27 minimum

### Peering issues

Ensure hub is deployed before spokes and firewall private IP is available.

## Related Modules

- **networking/spoke** - Spoke networks that peer to this hub
- **resource-group** - Creates resource groups for hub resources

## References

- [Hub-Spoke Network Topology](https://docs.microsoft.com/azure/architecture/reference-architectures/hybrid-networking/hub-spoke)
- [Azure Firewall](https://docs.microsoft.com/azure/firewall/)
- [Azure VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [Azure Bastion](https://docs.microsoft.com/azure/bastion/)

## Changelog

### Version 1.1.0
- Added Premium Firewall SKU support
- Made VPN Gateway subnet optional
- Added Bastion subnet support

### Version 1.0.0
- Initial release with hub VNet, Firewall, and Gateway subnet
