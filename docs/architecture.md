# Azure Landing Zone Architecture

## Overview

This document describes the architecture of the Azure Landing Zone deployed using a single subscription model with hub-spoke network topology.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Hub Virtual Network (10.0.0.0/16)         │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │   Gateway    │  │    Azure     │  │   Bastion   │ │ │
│  │  │   Subnet     │  │   Firewall   │  │   Subnet    │ │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │         Shared Services Subnet                   │ │ │
│  │  │  - Jump Boxes                                    │ │ │
│  │  │  - Domain Controllers                            │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
│                            │                                 │
│              ┌─────────────┴─────────────┐                  │
│              │     VNet Peering          │                  │
│              │                           │                  │
│    ┌─────────▼─────────┐       ┌────────▼────────┐        │
│    │  Dev Spoke VNet   │       │  Prod Spoke VNet │        │
│    │  (10.1.0.0/16)    │       │  (10.2.0.0/16)   │        │
│    │                   │       │                  │        │
│    │ ┌───────────────┐ │       │ ┌──────────────┐ │        │
│    │ │  App Subnet   │ │       │ │  App Subnet  │ │        │
│    │ └───────────────┘ │       │ └──────────────┘ │        │
│    │ ┌───────────────┐ │       │ ┌──────────────┐ │        │
│    │ │  Data Subnet  │ │       │ │  Data Subnet │ │        │
│    │ └───────────────┘ │       │ └──────────────┘ │        │
│    └───────────────────┘       └──────────────────┘        │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Management & Governance                   │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │     Log      │  │  Automation  │  │    Azure    │ │ │
│  │  │  Analytics   │  │   Account    │  │   Policy    │ │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐                  │ │
│  │  │  Key Vault   │  │   Security   │                  │ │
│  │  │              │  │    Center    │                  │ │
│  │  └──────────────┘  └──────────────┘                  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Hub Virtual Network

**Address Space**: 10.0.0.0/16

The hub VNet serves as the central point for connectivity and shared services.

**Subnets**:
- **GatewaySubnet** (10.0.0.0/27): For VPN or ExpressRoute Gateway
- **AzureFirewallSubnet** (10.0.1.0/26): For Azure Firewall
- **AzureBastionSubnet** (10.0.2.0/27): For Azure Bastion (secure RDP/SSH)
- **SharedServicesSubnet** (10.0.10.0/24): For jump boxes, domain controllers, etc.

**Key Resources**:
- Azure Firewall (Standard/Premium)
- VPN Gateway (optional)
- Azure Bastion (optional)
- Network Security Groups

### 2. Spoke Virtual Networks

#### Development Spoke
**Address Space**: 10.1.0.0/16

**Subnets**:
- **App Subnet** (10.1.1.0/24): Application tier
- **Data Subnet** (10.1.2.0/24): Database tier
- **Integration Subnet** (10.1.3.0/24): For integration services

#### Production Spoke
**Address Space**: 10.2.0.0/16

**Subnets**:
- **App Subnet** (10.2.1.0/24): Application tier
- **Data Subnet** (10.2.2.0/24): Database tier
- **Integration Subnet** (10.2.3.0/24): For integration services

**Features**:
- VNet peering to Hub
- User Defined Routes (UDR) to force traffic through Azure Firewall
- Network Security Groups on each subnet
- Service Endpoints for Azure PaaS services

### 3. Management & Governance

**Resource Group**: rg-management-{env}-{region}

**Components**:

#### Log Analytics Workspace
- Centralized logging and monitoring
- Retention: 90 days (production)
- Solutions enabled:
  - Security
  - Updates
  - Change Tracking
  - VM Insights
  - Azure Activity
  - Network Monitoring

#### Azure Automation Account
- Linked to Log Analytics
- Update Management
- Change Tracking
- Inventory

#### Diagnostic Storage Account
- Long-term diagnostic logs storage
- Geo-redundant (GRS)
- Versioning enabled

#### Action Groups
- Email notifications for alerts
- Integration with monitoring

### 4. Security

**Resource Group**: rg-security-{env}-{region}

**Components**:

#### Azure Key Vault
- Soft delete enabled (90 days retention)
- Purge protection enabled
- Network ACLs configured (deny by default)
- Diagnostic logging to Log Analytics
- Access policies for managed identities

#### Azure Policy
- Naming convention enforcement
- Required tags enforcement
- Allowed locations
- Allowed resource types
- Security baseline policies

### 5. Resource Organization

```
Resource Groups:
├── rg-terraform-state-{env}          # Terraform state storage
├── rg-network-hub-{env}-{region}     # Hub networking
├── rg-management-{env}-{region}      # Management resources
├── rg-security-{env}-{region}        # Security resources
├── rg-workload-dev-{env}-{region}    # Dev workload resources
└── rg-workload-prod-{env}-{region}   # Prod workload resources
```

## Network Traffic Flow

### Inbound Traffic
1. Internet → Azure Firewall Public IP
2. Azure Firewall inspects and applies rules
3. Traffic routed to appropriate spoke VNet
4. NSG rules applied at subnet level
5. Traffic reaches workload

### Outbound Traffic
1. Workload initiates outbound connection
2. UDR routes traffic to Azure Firewall
3. Azure Firewall inspects and applies rules
4. Traffic exits to internet or Azure services

### Spoke-to-Spoke Traffic
1. Traffic from Spoke A
2. UDR routes to Azure Firewall in Hub
3. Azure Firewall inspects and routes
4. Traffic reaches Spoke B

## Security Controls

### Network Security
- Azure Firewall for traffic inspection
- Network Security Groups on all subnets
- No direct internet access from spokes
- Private endpoints for PaaS services
- Just-in-Time VM access via Bastion

### Identity & Access
- Azure AD for authentication
- RBAC for resource access
- Managed identities for service-to-service auth
- Key Vault for secrets management

### Monitoring & Compliance
- Azure Policy for compliance enforcement
- Log Analytics for centralized logging
- Azure Monitor for alerting
- Security Center for security posture

## Scalability

This architecture supports growth through:

1. **Additional Spokes**: Create new spoke VNets for new workloads
2. **Subnet Expansion**: Sufficient address space for subnet growth
3. **Multiple Regions**: Replicate pattern in additional regions
4. **Subscription Boundaries**: Can be extended to multi-subscription model

## High Availability

- Azure Firewall: Built-in HA with 99.95% SLA
- VPN Gateway: Active-active configuration supported
- Log Analytics: Geo-redundant
- Storage Accounts: GRS replication

## Cost Optimization

- Right-sized firewall SKU (Standard vs Premium)
- Conditional deployment of optional components (Bastion, VPN Gateway)
- Appropriate Log Analytics retention
- Resource tagging for cost allocation

## Compliance

The architecture supports compliance with:
- Azure Security Benchmark
- CIS Azure Foundations
- NIST frameworks
- Industry-specific requirements through Azure Policy

## Next Steps

1. Review and customize network address spaces
2. Configure Azure Firewall rules
3. Set up Private DNS Zones
4. Deploy workload-specific resources
5. Configure backup and disaster recovery
6. Implement monitoring alerts
