# Azure Landing Zone Operations Guide

## Daily Operations

### Monitoring & Alerts

#### Check Azure Monitor Dashboard
```powershell
# Open Azure Portal
az portal browse --resource-group rg-management-prod-eastus
```

#### View Log Analytics Queries
```powershell
# Login to portal and navigate to Log Analytics Workspace
# Example queries:

# Failed login attempts
SecurityEvent
| where EventID == 4625
| summarize count() by Computer, Account

# Network traffic through firewall
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| summarize count() by Action

# Resource changes
AzureActivity
| where OperationNameValue contains "write"
| project TimeGenerated, Caller, ResourceGroup, Resource
```

### Backup & Recovery

#### Enable Azure Backup
```powershell
# Create Recovery Services Vault
az backup vault create `
  --resource-group rg-management-prod-eastus `
  --name rsv-prod-eastus `
  --location eastus

# Enable backup for VMs
az backup protection enable-for-vm `
  --resource-group rg-workload-prod-prod-eastus `
  --vault-name rsv-prod-eastus `
  --vm <vm-name> `
  --policy-name DefaultPolicy
```

### Access Management

#### Grant Access to Resources
```powershell
# Get Object ID of user/group
az ad user show --id user@example.com --query objectId -o tsv

# Assign RBAC role
az role assignment create `
  --assignee <object-id> `
  --role "Contributor" `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-workload-prod-prod-eastus"
```

#### Grant Key Vault Access
```powershell
# Add access policy
az keyvault set-policy `
  --name kv-prod-eastus-001 `
  --object-id <object-id> `
  --secret-permissions get list `
  --key-permissions get list
```

## Weekly Maintenance

### Update Management

#### Check for Updates
```powershell
# View update assessment
az automation software-update-configuration list `
  --automation-account-name aa-prod-eastus `
  --resource-group rg-management-prod-eastus
```

#### Schedule Updates
```powershell
# Create update schedule
az automation software-update-configuration create `
  --automation-account-name aa-prod-eastus `
  --resource-group rg-management-prod-eastus `
  --schedule-name "Weekly-Updates" `
  --frequency Week `
  --interval 1 `
  --operating-system Windows `
  --duration 120
```

### Security Reviews

#### Review NSG Rules
```powershell
# List NSG rules
az network nsg list --output table

# Show specific NSG rules
az network nsg rule list `
  --nsg-name nsg-snet-app `
  --resource-group rg-workload-prod-prod-eastus `
  --output table
```

#### Review Firewall Logs
```powershell
# Query firewall logs in Log Analytics
# Navigate to: rg-management-prod-eastus > law-prod-eastus > Logs

# Example query:
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule"
| where TimeGenerated > ago(7d)
| summarize count() by Fqdn_s, Action_s
```

### Cost Management

#### Review Costs
```powershell
# Show subscription costs
az consumption usage list `
  --start-date 2024-01-01 `
  --end-date 2024-01-31 `
  --output table

# Cost by resource group
az costmanagement query `
  --type Usage `
  --dataset-aggregation '{"totalCost":{"name":"Cost","function":"Sum"}}' `
  --dataset-grouping name="ResourceGroup" type="Dimension"
```

## Monthly Tasks

### Compliance Checks

#### Azure Policy Compliance
```powershell
# Check policy compliance
az policy state list `
  --filter "complianceState eq 'NonCompliant'" `
  --output table

# Get compliance summary
az policy state summarize `
  --resource "/subscriptions/$SUBSCRIPTION_ID"
```

#### Security Center Recommendations
```powershell
# List security recommendations
az security task list --output table

# Show high severity recommendations
az security task list `
  --query "[?properties.securityTaskParameters.severity=='High']" `
  --output table
```

### Capacity Planning

#### Check Resource Utilization
```powershell
# VM usage
az vm list-usage --location eastus --output table

# Network usage
az network list-usages --location eastus --output table

# Storage usage
az storage account show-usage --location eastus
```

### Documentation Updates

1. Update network diagrams if topology changed
2. Update runbooks for new procedures
3. Review and update access control documentation
4. Update disaster recovery plans

## Incident Response

### Network Issues

#### Test Connectivity
```powershell
# Test VNet connectivity
az network watcher test-connectivity `
  --source-resource <vm-resource-id> `
  --dest-address 10.2.1.10 `
  --dest-port 443

# Check effective routes
az network nic show-effective-route-table `
  --name <nic-name> `
  --resource-group <rg-name>

# Check effective NSG rules
az network nic list-effective-nsg `
  --name <nic-name> `
  --resource-group <rg-name>
```

#### Diagnose Firewall Issues
```powershell
# Enable firewall diagnostics (if not already enabled)
az monitor diagnostic-settings create `
  --name "firewall-diagnostics" `
  --resource <firewall-resource-id> `
  --workspace <log-analytics-id> `
  --logs '[{"category": "AzureFirewallApplicationRule","enabled": true}]'

# Check firewall health
az network firewall show `
  --name afw-vnet-hub-prod-eastus `
  --resource-group rg-network-hub-prod-eastus `
  --query provisioningState
```

### Security Incidents

#### Investigate Suspicious Activity
```powershell
# Check recent administrative actions
az monitor activity-log list `
  --start-time 2024-01-01T00:00:00Z `
  --end-time 2024-01-02T00:00:00Z `
  --query "[?contains(operationName.value, 'write')]"

# Review Key Vault access
# Navigate to Key Vault > Diagnostic settings > Logs
# Query: AuditEvent logs for unauthorized access attempts
```

#### Lock Down Resources
```powershell
# Apply resource lock immediately
az lock create `
  --name emergency-lock `
  --lock-type ReadOnly `
  --resource-group rg-workload-prod-prod-eastus `
  --notes "Emergency security lock"

# Revoke access
az role assignment delete `
  --assignee <object-id> `
  --scope <resource-scope>
```

### Performance Issues

#### Analyze Resource Performance
```powershell
# Get VM performance metrics
az monitor metrics list `
  --resource <vm-resource-id> `
  --metric "Percentage CPU" `
  --start-time 2024-01-01T00:00:00Z `
  --end-time 2024-01-02T00:00:00Z

# Get network metrics
az monitor metrics list `
  --resource <vnet-resource-id> `
  --metric "BytesInDDoS" `
  --start-time 2024-01-01T00:00:00Z
```

## Change Management

### Adding New Workload

1. **Create new spoke VNet configuration**:
   ```powershell
   # Copy existing spoke configuration
   cp -Recurse environments/prod/eastus/network-spoke-dev `
                environments/prod/eastus/network-spoke-new
   
   # Update terragrunt.hcl with new values
   ```

2. **Update address spaces** in the new terragrunt.hcl

3. **Deploy the new spoke**:
   ```powershell
   cd environments/prod/eastus/network-spoke-new
   terragrunt init
   terragrunt plan
   terragrunt apply
   ```

### Modifying Existing Infrastructure

1. **Make changes** in appropriate terragrunt.hcl file

2. **Preview changes**:
   ```powershell
   cd environments/prod/eastus/<component>
   terragrunt plan
   ```

3. **Review plan output** carefully

4. **Apply changes**:
   ```powershell
   terragrunt apply
   ```

5. **Verify deployment**:
   ```powershell
   # Check resource status
   az resource show --ids <resource-id>
   
   # Test connectivity if network changes
   ```

### Rollback Procedures

#### Terraform Rollback
```powershell
# List state file versions
az storage blob list `
  --container-name tfstate `
  --account-name sttfstateprod `
  --prefix "prod/eastus/<component>" `
  --query "[].{Name:name, LastModified:properties.lastModified}"

# Download previous state
az storage blob download `
  --container-name tfstate `
  --account-name sttfstateprod `
  --name "prod/eastus/<component>/terraform.tfstate" `
  --version-id <version-id> `
  --file terraform.tfstate.backup

# Apply previous configuration
terragrunt apply -auto-approve
```

## Emergency Procedures

### Complete Outage

1. **Assess impact** using Azure Status page and monitoring
2. **Check Azure Service Health** for platform issues
3. **Review recent changes** in Activity Log
4. **Escalate** to Microsoft Support if needed
5. **Communicate** with stakeholders
6. **Document** incident details

### Data Recovery

1. **Identify affected resources**
2. **Check backup status**:
   ```powershell
   az backup job list `
     --resource-group rg-management-prod-eastus `
     --vault-name rsv-prod-eastus
   ```
3. **Initiate restore** if needed
4. **Verify restored data**
5. **Update documentation**

## Automation Scripts

### Health Check Script
```powershell
# Save as: scripts/health-check.ps1
# Run: .\health-check.ps1 -Environment prod -Region eastus

# Checks:
# - Resource group existence
# - VNet peering status
# - Firewall status
# - Log Analytics ingestion
# - Key Vault accessibility
```

### Backup Verification Script
```powershell
# Save as: scripts/verify-backups.ps1
# Run: .\verify-backups.ps1 -Environment prod

# Checks:
# - Backup job status
# - Last successful backup time
# - Backup retention compliance
```

## Contacts

### Support Escalation

- **Azure Support**: Create ticket via Azure Portal
- **Internal Cloud Team**: cloudteam@example.com
- **Security Team**: security@example.com
- **On-Call Engineer**: oncall@example.com

### External Resources

- Azure Documentation: https://docs.microsoft.com/azure
- Azure Status: https://status.azure.com
- Terraform Azure Provider: https://registry.terraform.io/providers/hashicorp/azurerm
- Terragrunt Documentation: https://terragrunt.gruntwork.io
