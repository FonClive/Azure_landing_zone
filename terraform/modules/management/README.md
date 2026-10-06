# Management Module

## Overview

This module creates centralized management and monitoring infrastructure for Azure Landing Zone. It provides Log Analytics workspace, Automation Account, diagnostic storage, and action groups for alerting across all environments and workloads.

## Features

- ✅ Log Analytics workspace with configurable retention
- ✅ Multiple pre-configured Log Analytics solutions
- ✅ Azure Automation Account with update management
- ✅ Linked Log Analytics and Automation for enhanced capabilities
- ✅ Diagnostic storage account (GRS) for long-term log storage
- ✅ Action groups for alert notifications
- ✅ Support for multiple email receivers

## Architecture

```
Management Infrastructure
│
├── Log Analytics Workspace (90-day retention)
│   ├── Security Solution
│   ├── Updates Solution
│   ├── Change Tracking Solution
│   ├── VM Insights Solution
│   ├── Azure Activity Solution
│   └── Network Monitoring Solution
│
├── Automation Account
│   └── Linked to Log Analytics
│
├── Diagnostic Storage (GRS)
│   └── 30-day retention policy
│
└── Action Group
    ├── Email Receiver 1
    ├── Email Receiver 2
    └── ...
```

## Usage

### Basic Example

```hcl
module "management" {
  source = "../../modules/management"

  log_analytics_name       = "law-platform-eastus"
  location                 = "eastus"
  resource_group_name      = "rg-platform-management-eastus"
  automation_account_name  = "aa-platform-eastus"
  diagnostics_storage_name = "stplatformdiageastus"
  action_group_name        = "ag-platform-alerts"
  action_group_short_name  = "platform"
  
  email_receivers = [
    {
      name          = "Admin"
      email_address = "admin@example.com"
    }
  ]
  
  tags = {
    Tier      = "Platform"
    Component = "Management"
  }
}
```

### Complete Example with All Solutions

```hcl
module "management" {
  source = "../../modules/management"

  # Log Analytics
  log_analytics_name = "law-platform-eastus"
  location           = "eastus"
  resource_group_name = "rg-platform-management-eastus"
  log_analytics_sku   = "PerGB2018"
  retention_in_days   = 90
  
  # Solutions to enable
  log_analytics_solutions = [
    "Security",
    "Updates",
    "ChangeTracking",
    "VMInsights",
    "AzureActivity",
    "NetworkMonitoring",
    "SecurityCenterFree",
    "ContainerInsights"
  ]
  
  # Automation
  automation_account_name = "aa-platform-eastus"
  
  # Diagnostics Storage
  diagnostics_storage_name = "stplatformdiageastus"
  
  # Action Group
  action_group_name       = "ag-platform-critical"
  action_group_short_name = "platform"
  
  email_receivers = [
    {
      name          = "PlatformTeam"
      email_address = "platform-team@example.com"
    },
    {
      name          = "CloudOps"
      email_address = "cloudops@example.com"
    },
    {
      name          = "SecurityTeam"
      email_address = "security@example.com"
    }
  ]
  
  tags = {
    Tier        = "Platform"
    Component   = "Management"
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
| log_analytics_name | Name of Log Analytics workspace | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| log_analytics_sku | SKU for Log Analytics | `string` | `"PerGB2018"` | no |
| retention_in_days | Retention period in days | `number` | `30` | no |
| log_analytics_solutions | List of solutions to enable | `list(string)` | See below | no |
| automation_account_name | Name of Automation Account | `string` | n/a | yes |
| diagnostics_storage_name | Name of diagnostic storage | `string` | n/a | yes |
| action_group_name | Name of action group | `string` | n/a | yes |
| action_group_short_name | Short name (max 12 chars) | `string` | n/a | yes |
| email_receivers | List of email receivers | `list(object)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Default Log Analytics Solutions

```hcl
[
  "Security",
  "Updates",
  "ChangeTracking",
  "VMInsights",
  "AzureActivity"
]
```

## Outputs

| Name | Description |
|------|-------------|
| log_analytics_workspace_id | Log Analytics Workspace ID |
| log_analytics_workspace_key | Log Analytics Workspace Key (sensitive) |
| automation_account_id | Automation Account ID |
| diagnostics_storage_id | Diagnostics Storage Account ID |
| action_group_id | Action Group ID |

## Log Analytics Solutions

### Available Solutions

| Solution | Purpose | Use Case |
|----------|---------|----------|
| **Security** | Security event collection and analysis | All environments |
| **Updates** | Update assessment and deployment | VM management |
| **ChangeTracking** | Track configuration changes | Compliance |
| **VMInsights** | VM performance and dependencies | VM monitoring |
| **AzureActivity** | Activity log analysis | Audit and compliance |
| **NetworkMonitoring** | Network performance monitoring | Network troubleshooting |
| **SecurityCenterFree** | Basic security recommendations | All environments |
| **ContainerInsights** | Container monitoring (AKS/ACI) | Container workloads |
| **SQLAdvancedThreatProtection** | SQL threat detection | SQL databases |
| **AntiMalware** | Malware assessment | Windows VMs |

### Recommended Solutions by Environment

**Platform/Shared:**
```hcl
log_analytics_solutions = [
  "Security",
  "Updates",
  "ChangeTracking",
  "VMInsights",
  "AzureActivity",
  "NetworkMonitoring"
]
```

**Development:**
```hcl
log_analytics_solutions = [
  "VMInsights",
  "AzureActivity",
  "ContainerInsights"
]
```

**Production:**
```hcl
log_analytics_solutions = [
  "Security",
  "Updates",
  "ChangeTracking",
  "VMInsights",
  "AzureActivity",
  "NetworkMonitoring",
  "SQLAdvancedThreatProtection",
  "AntiMalware"
]
```

## Log Analytics SKUs

| SKU | Description | Pricing | Use Case |
|-----|-------------|---------|----------|
| **PerGB2018** | Pay per GB ingested | $2.30/GB | Recommended for most |
| **CapacityReservation** | Reserved capacity | Starts at $196/day (100GB) | High volume, predictable |

## Retention Periods

| Retention | Cost | Use Case |
|-----------|------|----------|
| 30 days | Included | Development |
| 90 days | $0.10/GB/month | Production (recommended) |
| 180 days | $0.10/GB/month | Compliance |
| 365 days | $0.10/GB/month | Long-term compliance |
| 730 days | $0.10/GB/month | Legal requirements |

## Diagnostic Storage Configuration

The module creates a storage account with:
- **Replication**: GRS (Geo-Redundant Storage)
- **TLS Version**: 1.2 minimum
- **Blob Retention**: 30 days
- **Purpose**: Long-term diagnostic log storage

```hcl
# Use for diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "diag-example"
  target_resource_id = azurerm_resource.example.id
  
  storage_account_id = module.management.diagnostics_storage_id
  
  log {
    category = "AuditEvent"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = 90
    }
  }
}
```

## Action Groups

Action groups define who gets notified when alerts fire:

```hcl
email_receivers = [
  {
    name          = "PlatformTeam"
    email_address = "platform-team@example.com"
  },
  {
    name          = "OnCall"
    email_address = "oncall@example.com"
  }
]
```

### Adding Additional Receiver Types

```hcl
# SMS receiver
resource "azurerm_monitor_action_group" "extended" {
  name                = "ag-extended"
  resource_group_name = var.resource_group_name
  short_name          = "extended"
  
  email_receiver {
    name          = "Admin"
    email_address = "admin@example.com"
  }
  
  sms_receiver {
    name         = "OnCall"
    country_code = "1"
    phone_number = "5551234567"
  }
  
  webhook_receiver {
    name        = "Teams"
    service_uri = "https://outlook.office.com/webhook/..."
  }
}
```

## Automation Account

The Automation Account is linked to Log Analytics for:
- **Update Management**: Schedule and track OS updates
- **Change Tracking**: Track system changes
- **Inventory**: Collect software inventory
- **Start/Stop VMs**: Schedule VM start/stop

### Enable Update Management

```bash
# Link VMs to update management
az vm extension set \
  --resource-group rg-workload-prod-eastus \
  --vm-name vm-app-prod-01 \
  --name MicrosoftMonitoringAgent \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings "{\"workspaceId\":\"<workspace-id>\"}" \
  --protected-settings "{\"workspaceKey\":\"<workspace-key>\"}"
```

## Common Log Queries

### Failed Login Attempts
```kql
SecurityEvent
| where EventID == 4625
| summarize FailedAttempts = count() by Account, Computer
| order by FailedAttempts desc
```

### Resource Changes in Last 24 Hours
```kql
AzureActivity
| where OperationNameValue contains "write"
| where TimeGenerated > ago(24h)
| project TimeGenerated, Caller, ResourceGroup, ResourceType = Type, OperationName
| order by TimeGenerated desc
```

### VM Performance Issues
```kql
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| where CounterValue > 80
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart
```

### Firewall Blocks
```kql
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule" or Category == "AzureFirewallNetworkRule"
| where Action == "Deny"
| summarize Count = count() by Fqdn_s, DestinationPort_d
| order by Count desc
```

### Networking Issues
```kql
AzureDiagnostics
| where ResourceType == "NETWORKSECURITYGROUPS"
| where Type == "AzureNetworkSecurityGroupFlowLog"
| project TimeGenerated, FlowTuple = split(flowTuple_s, ",")
| extend SourceIP = tostring(FlowTuple[0])
| extend DestPort = tostring(FlowTuple[3])
| extend Action = tostring(FlowTuple[5])
| where Action == "D"  // Denied
| summarize Count = count() by SourceIP, DestPort
```

## Workbook Integration

Create Azure Workbooks for visualization:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureActivity\n| summarize Count = count() by OperationNameValue\n| top 10 by Count",
        "size": 0,
        "title": "Top 10 Operations",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.operationalinsights/workspaces"
      }
    }
  ]
}
```

## Alerts Configuration

Create alerts using the action group:

```hcl
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_virtual_machine.example.id]
  description         = "Alert when CPU exceeds 80%"
  
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = module.management.action_group_id
  }
}
```

## Cost Optimization

### Log Analytics Costs

**Per GB2018 Pricing (approximate):**
- Ingestion: $2.30/GB
- Retention (beyond 30 days): $0.10/GB/month

**Typical Ingestion Rates:**
- VM (Windows): 1-3 GB/month
- VM (Linux): 0.5-1 GB/month
- AKS Cluster: 10-30 GB/month
- Azure Firewall: 5-15 GB/month

**Example Monthly Cost (10 VMs + Firewall):**
- Ingestion: 25 GB × $2.30 = $57.50
- Retention (90 days): 25 GB × 2 months × $0.10 = $5.00
- **Total**: ~$62.50/month

### Optimization Tips

1. **Filter Data**: Don't collect unnecessary logs
2. **Sampling**: Use sampling for high-volume data
3. **Retention**: Use shorter retention for dev environments
4. **Archive**: Move old logs to cheaper storage
5. **Solutions**: Only enable needed solutions

## Best Practices

1. **Centralize Logging**: Use single Log Analytics for all environments
2. **Retention Policy**: Match compliance requirements
3. **Alert Tuning**: Avoid alert fatigue with proper thresholds
4. **Access Control**: Use RBAC to control Log Analytics access
5. **Capacity Reservations**: Consider for > 100 GB/day ingestion
6. **Diagnostic Settings**: Enable on all resources
7. **Regular Reviews**: Review queries and dashboards monthly

## Security Considerations

1. **Workspace Key**: Treat as sensitive (stored in Terraform state)
2. **RBAC**: Use Log Analytics Reader for read-only access
3. **Private Link**: Consider for sensitive environments
4. **Data Export**: Enable for long-term storage
5. **Audit Access**: Monitor who accesses logs

## Troubleshooting

### No data in Log Analytics

1. Check diagnostic settings are enabled on resources
2. Verify workspace ID and key are correct
3. Check firewall rules allow log ingestion
4. Wait 10-15 minutes for initial data

### High costs

1. Review ingestion by resource:
   ```kql
   Usage
   | where TimeGenerated > ago(30d)
   | summarize TotalGB = sum(Quantity) / 1024 by Solution
   | order by TotalGB desc
   ```

2. Identify high-volume resources
3. Adjust data collection rules
4. Consider capacity reservation

### Automation runbooks not working

1. Check Automation Account is linked to Log Analytics
2. Verify Automation Account has necessary permissions
3. Check runbook logs for errors

## Related Modules

- **networking/hub** - Sends firewall logs to Log Analytics
- **networking/spoke** - Sends NSG flow logs to Log Analytics
- **security/key-vault** - Sends audit logs to Log Analytics

## References

- [Log Analytics Overview](https://docs.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)
- [Log Analytics Pricing](https://azure.microsoft.com/pricing/details/monitor/)
- [KQL Reference](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [Azure Automation](https://docs.microsoft.com/azure/automation/overview)
- [Action Groups](https://docs.microsoft.com/azure/azure-monitor/alerts/action-groups)

## Changelog

### Version 1.1.0
- Added support for multiple email receivers
- Added diagnostic storage with retention policy
- Linked Automation Account to Log Analytics

### Version 1.0.0
- Initial release with Log Analytics, Automation, and Action Groups
