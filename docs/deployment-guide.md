# Azure Landing Zone Deployment Guide

## Prerequisites

### Required Tools

1. **Azure CLI** (v2.50.0 or later)
   ```powershell
   # Install on Windows
   winget install Microsoft.AzureCLI
   
   # Verify installation
   az --version
   ```

2. **Terraform** (v1.5.0 or later)
   ```powershell
   # Install on Windows using Chocolatey
   choco install terraform
   
   # Or download from https://www.terraform.io/downloads
   
   # Verify installation
   terraform version
   ```

3. **Terragrunt** (v0.50.0 or later)
   ```powershell
   # Download from https://terragrunt.gruntwork.io/docs/getting-started/install/
   
   # Verify installation
   terragrunt --version
   ```

4. **PowerShell** (v7.0 or later)
   ```powershell
   # Install PowerShell 7
   winget install Microsoft.PowerShell
   ```

### Azure Permissions

You need the following permissions in the target Azure subscription:

- **Owner** or **Contributor + User Access Administrator** role
- Ability to create resource groups
- Ability to create service principals (if using automated deployments)

### Azure Subscription Setup

1. **Login to Azure**:
   ```powershell
   az login
   ```

2. **Set the subscription**:
   ```powershell
   az account set --subscription "Your-Subscription-Name-Or-ID"
   ```

3. **Verify subscription**:
   ```powershell
   az account show
   ```

## Configuration

### 1. Update Variables

Before deployment, review and customize the configuration files:

#### Environment Configuration

Edit `environments/prod/eastus/resource-groups/terragrunt.hcl`:
- Update resource group names
- Adjust locations
- Modify lock levels

#### Network Configuration

Edit `environments/prod/eastus/network-hub/terragrunt.hcl`:
- Customize address spaces
- Enable/disable VPN Gateway
- Configure Azure Firewall settings

Edit spoke configurations:
- `environments/prod/eastus/network-spoke-dev/terragrunt.hcl`
- `environments/prod/eastus/network-spoke-prod/terragrunt.hcl`

#### Management Configuration

Edit `environments/prod/eastus/management/terragrunt.hcl`:
- Update Log Analytics retention
- Configure email receivers for alerts
- Adjust storage account names (must be globally unique)

#### Security Configuration

Edit `environments/prod/eastus/security/terragrunt.hcl`:
- Update Key Vault name (must be globally unique)
- Configure network ACLs
- Set access policies

### 2. Naming Conventions

Follow these naming conventions:

| Resource Type | Format | Example |
|---------------|--------|---------|
| Resource Group | `rg-{purpose}-{env}-{region}` | `rg-network-hub-prod-eastus` |
| Virtual Network | `vnet-{purpose}-{env}-{region}` | `vnet-hub-prod-eastus` |
| Subnet | `snet-{purpose}` | `snet-app` |
| Storage Account | `st{purpose}{env}{region}{num}` | `stdiagprodeastus001` |
| Key Vault | `kv-{env}-{region}-{num}` | `kv-prod-eastus-001` |
| Log Analytics | `law-{env}-{region}` | `law-prod-eastus` |

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

Use the provided PowerShell deployment script:

```powershell
# Navigate to scripts directory
cd scripts

# Run deployment script
.\deploy.ps1 -Environment prod -Region eastus -SubscriptionId "xxxx-xxxx-xxxx-xxxx"

# For a dry-run (preview changes without applying):
.\deploy.ps1 -Environment prod -Region eastus -SubscriptionId "xxxx-xxxx-xxxx-xxxx" -WhatIf
```

The script will:
1. Check prerequisites
2. Verify Azure authentication
3. Create Terraform state storage
4. Deploy components in the correct order
5. Display progress and results

### Option 2: Manual Deployment

#### Step 1: Initialize State Storage

```powershell
# Create resource group for state
az group create `
  --name rg-terraform-state-prod `
  --location eastus `
  --tags Environment=prod ManagedBy=Terraform

# Create storage account
az storage account create `
  --name sttfstateprod `
  --resource-group rg-terraform-state-prod `
  --location eastus `
  --sku Standard_GRS `
  --encryption-services blob

# Create container
az storage container create `
  --name tfstate `
  --account-name sttfstateprod `
  --auth-mode login
```

#### Step 2: Deploy Resource Groups

```powershell
cd environments/prod/eastus/resource-groups
terragrunt init
terragrunt plan
terragrunt apply
```

#### Step 3: Deploy Management

```powershell
cd ../management
terragrunt init
terragrunt plan
terragrunt apply
```

#### Step 4: Deploy Hub Network

```powershell
cd ../network-hub
terragrunt init
terragrunt plan
terragrunt apply
```

#### Step 5: Deploy Spoke Networks

```powershell
# Development spoke
cd ../network-spoke-dev
terragrunt init
terragrunt plan
terragrunt apply

# Production spoke
cd ../network-spoke-prod
terragrunt init
terragrunt plan
terragrunt apply
```

#### Step 6: Deploy Security

```powershell
cd ../security
terragrunt init
terragrunt plan
terragrunt apply
```

## Post-Deployment Configuration

### 1. Azure Firewall Rules

Configure firewall rules for your workloads:

```powershell
# Example: Allow outbound HTTPS
az network firewall network-rule create `
  --collection-name "AllowWeb" `
  --destination-ports 443 `
  --firewall-name "afw-vnet-hub-prod-eastus" `
  --name "AllowHTTPS" `
  --protocols TCP `
  --resource-group "rg-network-hub-prod-eastus" `
  --source-addresses "10.1.0.0/16" "10.2.0.0/16" `
  --destination-addresses "*" `
  --action Allow `
  --priority 100
```

### 2. Azure Policy Assignment

Apply custom policies:

```powershell
# Assign naming convention policy
az policy assignment create `
  --name "naming-convention" `
  --policy "../policies/naming-convention.json" `
  --scope "/subscriptions/YOUR-SUBSCRIPTION-ID"

# Assign required tags policy
az policy assignment create `
  --name "required-tags" `
  --policy "../policies/required-tags.json" `
  --scope "/subscriptions/YOUR-SUBSCRIPTION-ID"
```

### 3. Configure Private DNS Zones

```powershell
# Create Private DNS Zone for Azure services
az network private-dns zone create `
  --resource-group rg-network-hub-prod-eastus `
  --name privatelink.database.windows.net

# Link to VNets
az network private-dns link vnet create `
  --resource-group rg-network-hub-prod-eastus `
  --zone-name privatelink.database.windows.net `
  --name hub-link `
  --virtual-network vnet-hub-prod-eastus `
  --registration-enabled false
```

### 4. Set Up Diagnostic Settings

Diagnostic settings are configured automatically via Terraform for Key Vault. For additional resources:

```powershell
# Enable diagnostics for NSGs
az monitor diagnostic-settings create `
  --name "nsg-diagnostics" `
  --resource "/subscriptions/SUB-ID/resourceGroups/RG-NAME/providers/Microsoft.Network/networkSecurityGroups/NSG-NAME" `
  --workspace "/subscriptions/SUB-ID/resourcegroups/rg-management-prod-eastus/providers/microsoft.operationalinsights/workspaces/law-prod-eastus" `
  --logs '[{"category": "NetworkSecurityGroupEvent","enabled": true},{"category": "NetworkSecurityGroupRuleCounter","enabled": true}]'
```

## Validation

### 1. Run Validation Script

```powershell
cd scripts
.\validate.ps1 -Environment prod
```

### 2. Manual Validation Checks

Check resource groups:
```powershell
az group list --output table
```

Check virtual networks:
```powershell
az network vnet list --output table
```

Check VNet peerings:
```powershell
az network vnet peering list `
  --resource-group rg-network-hub-prod-eastus `
  --vnet-name vnet-hub-prod-eastus `
  --output table
```

Check firewall:
```powershell
az network firewall show `
  --name afw-vnet-hub-prod-eastus `
  --resource-group rg-network-hub-prod-eastus
```

### 3. Connectivity Tests

Test connectivity from a VM in spoke to internet:
```powershell
# From within a VM
Test-NetConnection -ComputerName google.com -Port 443
```

## Troubleshooting

### Common Issues

1. **State Storage Access Denied**
   - Ensure you have Storage Blob Data Contributor role
   - Verify authentication with `az login`

2. **Terraform Lock Timeout**
   ```powershell
   # Release lock manually
   terragrunt force-unlock LOCK-ID
   ```

3. **Name Already Exists**
   - Storage accounts and Key Vaults must have globally unique names
   - Update names in terragrunt.hcl files

4. **Quota Exceeded**
   - Check subscription quotas: `az vm list-usage --location eastus`
   - Request quota increase if needed

5. **Dependency Errors**
   - Deploy components in order: resource-groups → management → hub → spokes → security
   - Check dependency blocks in terragrunt.hcl

### Enable Debug Logging

```powershell
# Terraform debug
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "./terraform-debug.log"

# Terragrunt debug
terragrunt plan --terragrunt-log-level debug
```

## Cleanup

To destroy all resources:

```powershell
cd scripts
.\destroy.ps1 -Environment prod -Region eastus -SubscriptionId "xxxx-xxxx-xxxx-xxxx"
```

**Warning**: This will permanently delete all resources. Type 'DELETE' when prompted to confirm.

## Next Steps

1. Deploy workload resources in spoke VNets
2. Configure backup policies
3. Set up Azure Monitor alerts
4. Implement CI/CD pipelines
5. Document operational procedures

## Support

For issues or questions:
1. Check the [Architecture Documentation](./architecture.md)
2. Review Terraform/Terragrunt logs
3. Consult Azure documentation
4. Review module source code in `terraform/modules/`
