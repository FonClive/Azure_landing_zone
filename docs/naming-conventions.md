# Azure Resource Naming Conventions

## Overview

This document defines the naming conventions used in the Azure Landing Zone. Following consistent naming conventions helps with:

- Resource organization and discovery
- Cost allocation and tracking
- Automation and scripting
- Access control and security
- Compliance and governance

## General Naming Rules

1. **Use lowercase letters** for resource names
2. **Use hyphens** to separate words (except where not allowed)
3. **Be descriptive** but concise
4. **Include environment** and region where appropriate
5. **Follow Azure naming restrictions** for each resource type

## Abbreviations

### Common Abbreviations

| Full Name | Abbreviation |
|-----------|--------------|
| Resource Group | rg |
| Virtual Network | vnet |
| Subnet | snet |
| Network Security Group | nsg |
| Route Table | rt |
| Virtual Machine | vm |
| Storage Account | st |
| Key Vault | kv |
| Log Analytics Workspace | law |
| Automation Account | aa |
| Recovery Services Vault | rsv |
| Application Gateway | agw |
| Azure Firewall | afw |
| Public IP | pip |
| Network Interface | nic |
| Load Balancer | lb |
| Application Insights | appi |

### Environment Abbreviations

| Environment | Abbreviation |
|-------------|--------------|
| Production | prod |
| Development | dev |
| Testing | test |
| Staging | stg |
| Quality Assurance | qa |

### Region Abbreviations

| Region | Abbreviation |
|--------|--------------|
| East US | eastus |
| East US 2 | eastus2 |
| West US | westus |
| West US 2 | westus2 |
| Central US | centralus |
| North Europe | northeu |
| West Europe | westeu |

## Resource-Specific Naming

### Resource Groups

**Format**: `rg-{purpose}-{env}-{region}`

**Examples**:
- `rg-network-hub-prod-eastus`
- `rg-management-prod-eastus`
- `rg-workload-dev-prod-eastus`
- `rg-security-prod-eastus`

**Notes**:
- Maximum 90 characters
- Alphanumerics, underscores, parentheses, hyphens, periods

### Networking

#### Virtual Networks

**Format**: `vnet-{purpose}-{env}-{region}`

**Examples**:
- `vnet-hub-prod-eastus`
- `vnet-spoke-prod-prod-eastus`
- `vnet-spoke-dev-prod-eastus`

#### Subnets

**Format**: `snet-{purpose}`

**Examples**:
- `snet-app`
- `snet-data`
- `snet-integration`
- `snet-shared-services`

**Special Subnets** (Azure-required names):
- `GatewaySubnet`
- `AzureFirewallSubnet`
- `AzureBastionSubnet`

#### Network Security Groups

**Format**: `nsg-{subnet-name}` or `nsg-{resource-name}`

**Examples**:
- `nsg-snet-app`
- `nsg-snet-data`
- `nsg-shared-services`

#### Route Tables

**Format**: `rt-{vnet-name}` or `rt-{subnet-name}`

**Examples**:
- `rt-vnet-spoke-prod-prod-eastus`
- `rt-snet-app`

#### Azure Firewall

**Format**: `afw-{vnet-name}`

**Examples**:
- `afw-vnet-hub-prod-eastus`

#### Public IP Addresses

**Format**: `pip-{resource-name}-{purpose}`

**Examples**:
- `pip-vnet-hub-prod-eastus-fw`
- `pip-agw-prod-eastus`
- `pip-vm-jumpbox-prod`

### Compute

#### Virtual Machines

**Format**: `vm-{workload}-{env}-{region}-{instance}`

**Examples**:
- `vm-web-prod-eastus-01`
- `vm-app-dev-eastus-01`
- `vm-jumpbox-prod-eastus-01`

**Notes**:
- Windows VMs: 15 characters maximum
- Linux VMs: 64 characters maximum

#### Availability Sets

**Format**: `avail-{workload}-{env}`

**Examples**:
- `avail-web-prod`
- `avail-app-prod`

### Storage

#### Storage Accounts

**Format**: `st{purpose}{env}{region}{instance}`

**Examples**:
- `stdiagprodeastus001`
- `stappdeveastus001`
- `sttfstateprod`

**Notes**:
- 3-24 characters
- Lowercase letters and numbers only
- Must be globally unique

#### Storage Containers

**Format**: `{purpose}-{detail}`

**Examples**:
- `tfstate`
- `logs-application`
- `backup-vm`

### Security & Identity

#### Key Vault

**Format**: `kv-{env}-{region}-{instance}`

**Examples**:
- `kv-prod-eastus-001`
- `kv-dev-eastus-001`

**Notes**:
- 3-24 characters
- Alphanumerics and hyphens
- Must be globally unique

### Management & Monitoring

#### Log Analytics Workspace

**Format**: `law-{env}-{region}`

**Examples**:
- `law-prod-eastus`
- `law-dev-westus2`

#### Automation Account

**Format**: `aa-{env}-{region}`

**Examples**:
- `aa-prod-eastus`
- `aa-dev-eastus`

#### Action Group

**Format**: `ag-{purpose}-{env}`

**Examples**:
- `ag-landing-zone-prod`
- `ag-critical-alerts-prod`

#### Recovery Services Vault

**Format**: `rsv-{env}-{region}`

**Examples**:
- `rsv-prod-eastus`
- `rsv-dev-eastus`

### Application Services

#### App Service

**Format**: `app-{workload}-{env}-{region}`

**Examples**:
- `app-portal-prod-eastus`
- `app-api-dev-eastus`

#### Function App

**Format**: `func-{workload}-{env}-{region}`

**Examples**:
- `func-processor-prod-eastus`
- `func-webhook-dev-eastus`

#### Application Insights

**Format**: `appi-{workload}-{env}`

**Examples**:
- `appi-portal-prod`
- `appi-api-dev`

### Database

#### SQL Server

**Format**: `sql-{workload}-{env}-{region}`

**Examples**:
- `sql-app-prod-eastus`
- `sql-reporting-dev-eastus`

#### SQL Database

**Format**: `sqldb-{workload}-{env}`

**Examples**:
- `sqldb-app-prod`
- `sqldb-reporting-dev`

#### Cosmos DB

**Format**: `cosmos-{workload}-{env}-{region}`

**Examples**:
- `cosmos-app-prod-eastus`
- `cosmos-cache-dev-eastus`

## Tagging Strategy

All resources should be tagged with:

### Mandatory Tags

| Tag Name | Description | Example |
|----------|-------------|---------|
| Environment | Deployment environment | Production, Development, Test |
| ManagedBy | Management method | Terraform, Manual |
| Owner | Responsible team/person | CloudTeam, john.doe@example.com |
| CostCenter | Cost allocation | IT-Infrastructure, APP-001 |
| Project | Project name | LandingZone, AppMigration |

### Optional Tags

| Tag Name | Description | Example |
|----------|-------------|---------|
| Application | Application name | PortalApp, DataPipeline |
| BusinessUnit | Business unit | Finance, Sales |
| Compliance | Compliance requirements | PCI, HIPAA, GDPR |
| DataClassification | Data sensitivity | Public, Confidential, Restricted |
| DisasterRecovery | DR requirement | Critical, Important, NonCritical |
| Backup | Backup policy | Daily, Weekly, None |

### Example Tag Implementation

```hcl
tags = {
  Environment        = "Production"
  ManagedBy          = "Terraform"
  Owner              = "CloudTeam"
  CostCenter         = "IT-Infrastructure"
  Project            = "LandingZone"
  Application        = "CoreInfrastructure"
  BusinessUnit       = "IT"
  DataClassification = "Internal"
  DisasterRecovery   = "Critical"
}
```

## Validation

Azure Policies are configured to enforce naming conventions:

1. **Naming Convention Policy**: Validates resource names against regex patterns
2. **Required Tags Policy**: Ensures mandatory tags are present
3. **Allowed Locations Policy**: Restricts resource deployment to approved regions

## References

- [Azure Naming Conventions Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Azure Resource Naming Restrictions](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)
- [Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
