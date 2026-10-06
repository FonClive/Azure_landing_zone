# Key Vault Module

## Overview

This module creates and configures an Azure Key Vault for storing secrets, keys, and certificates. It includes network ACLs, access policies, diagnostic logging, and security features like soft delete and purge protection.

## Features

- ✅ Azure Key Vault with configurable SKU (Standard/Premium)
- ✅ Soft delete with configurable retention (7-90 days)
- ✅ Purge protection for production environments
- ✅ Network ACLs (deny by default)
- ✅ Whitelist specific IPs and subnets
- ✅ Access policies for users and service principals
- ✅ Diagnostic logging to Log Analytics
- ✅ Support for VM deployment, disk encryption, and template deployment

## Architecture

```
Key Vault
├── Network ACLs
│   ├── Default Action: Deny
│   ├── Bypass: AzureServices
│   ├── Allowed IPs: [Admin IPs]
│   └── Allowed Subnets: [Platform Subnets]
│
├── Access Policies
│   ├── Platform Team: Full
│   ├── App Service: Get Secrets
│   └── Automation Account: Get/List Secrets
│
├── Features
│   ├── Soft Delete: 90 days
│   ├── Purge Protection: Enabled
│   └── Diagnostic Logs: Enabled
│
└── Integrations
    ├── VM Deployment: Optional
    ├── Disk Encryption: Enabled
    └── Template Deployment: Enabled
```

## Usage

### Basic Example

```hcl
module "key_vault" {
  source = "../../modules/security/key-vault"

  key_vault_name      = "kv-platform-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-security-eastus"
  
  tags = {
    Tier      = "Platform"
    Component = "Security"
  }
}
```

### Complete Example with Network ACLs and Access Policies

```hcl
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "../../modules/security/key-vault"

  key_vault_name      = "kv-platform-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-security-eastus"
  
  # SKU
  sku_name = "standard"  # or "premium" for HSM-backed keys
  
  # Security features
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  
  # Azure services integration
  enabled_for_deployment          = false  # VM deployment
  enabled_for_disk_encryption     = true   # Disk encryption
  enabled_for_template_deployment = true   # ARM templates
  
  # Network ACLs
  default_network_acl_action = "Deny"
  allowed_ip_ranges = [
    "203.0.113.0/24",     # Office network
    "198.51.100.50/32"    # Admin workstation
  ]
  allowed_subnet_ids = [
    module.hub_network.shared_services_subnet_id,
    module.spoke_prod.subnet_ids["snet-app"]
  ]
  
  # Access Policies
  access_policies = {
    platform_team = {
      object_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      key_permissions = [
        "Get", "List", "Create", "Delete", "Update",
        "Import", "Backup", "Restore", "Recover"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete",
        "Backup", "Restore", "Recover"
      ]
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Update",
        "Import", "Backup", "Restore", "Recover"
      ]
    }
    app_service = {
      object_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
      secret_permissions = ["Get", "List"]
    }
    automation_account = {
      object_id = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
      secret_permissions = ["Get", "List"]
      key_permissions    = ["Get", "List"]
    }
  }
  
  # Diagnostics
  log_analytics_workspace_id = module.management.log_analytics_workspace_id
  
  tags = {
    Tier        = "Platform"
    Component   = "Security"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Workload Key Vault Example

```hcl
module "workload_key_vault" {
  source = "../../modules/security/key-vault"

  key_vault_name      = "kv-prod-app1-eastus"
  location            = "eastus"
  resource_group_name = "rg-prod-shared-eastus"
  sku_name            = "standard"
  
  # Less restrictive for dev, more restrictive for prod
  soft_delete_retention_days = 30
  purge_protection_enabled   = false  # Allow purge in dev
  
  # Allow from workload subnet
  default_network_acl_action = "Deny"
  allowed_subnet_ids = [
    module.spoke_prod.subnet_ids["snet-app"]
  ]
  
  access_policies = {
    app_identity = {
      object_id = azurerm_user_assigned_identity.app.principal_id
      secret_permissions = ["Get", "List"]
    }
  }
  
  log_analytics_workspace_id = module.management.log_analytics_workspace_id
  
  tags = {
    Tier        = "Workload"
    Environment = "Production"
    Application = "App1"
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
| key_vault_name | Name of Key Vault (globally unique) | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| sku_name | SKU (standard or premium) | `string` | `"standard"` | no |
| soft_delete_retention_days | Soft delete retention (7-90) | `number` | `90` | no |
| purge_protection_enabled | Enable purge protection | `bool` | `true` | no |
| enabled_for_deployment | Enable for VM deployment | `bool` | `false` | no |
| enabled_for_disk_encryption | Enable for disk encryption | `bool` | `true` | no |
| enabled_for_template_deployment | Enable for template deployment | `bool` | `true` | no |
| default_network_acl_action | Default network action | `string` | `"Deny"` | no |
| allowed_ip_ranges | Allowed IP ranges | `list(string)` | `[]` | no |
| allowed_subnet_ids | Allowed subnet IDs | `list(string)` | `[]` | no |
| access_policies | Map of access policies | `map(object)` | `{}` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

### Access Policy Object Structure

```hcl
access_policies = {
  policy_name = {
    object_id               = string                # Required
    key_permissions         = optional(list(string))
    secret_permissions      = optional(list(string))
    certificate_permissions = optional(list(string))
    storage_permissions     = optional(list(string))
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | Key Vault ID |
| key_vault_uri | Key Vault URI |
| key_vault_name | Key Vault name |

## SKU Comparison

| Feature | Standard | Premium |
|---------|----------|---------|
| Secrets | ✅ | ✅ |
| Keys (Software) | ✅ | ✅ |
| Keys (HSM-backed) | ❌ | ✅ |
| Certificates | ✅ | ✅ |
| HSM Protection | ❌ | ✅ |
| Cost | Lower | Higher (~5x) |

**Recommendation**: Use Standard unless you need HSM-backed keys.

## Permission Levels

### Administrator (Full Access)
```hcl
key_permissions = [
  "Get", "List", "Create", "Delete", "Update",
  "Import", "Backup", "Restore", "Recover", "Purge"
]
secret_permissions = [
  "Get", "List", "Set", "Delete",
  "Backup", "Restore", "Recover", "Purge"
]
certificate_permissions = [
  "Get", "List", "Create", "Delete", "Update",
  "Import", "ManageContacts", "ManageIssuers",
  "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers",
  "Backup", "Restore", "Recover", "Purge"
]
```

### Application (Read-Only)
```hcl
secret_permissions = ["Get", "List"]
key_permissions    = ["Get", "List"]
```

### Application (Read/Write)
```hcl
secret_permissions = ["Get", "List", "Set"]
key_permissions    = ["Get", "List", "Create", "Update"]
```

### Backup Service
```hcl
secret_permissions = ["Get", "List", "Backup"]
key_permissions    = ["Get", "List", "Backup"]
```

## Soft Delete and Purge Protection

### Soft Delete
- **Retention**: 7-90 days (default: 90)
- **Purpose**: Recover accidentally deleted items
- **Cost**: No additional cost

```bash
# Recover deleted secret
az keyvault secret recover --vault-name kv-platform-eastus --name MySecret

# List deleted secrets
az keyvault secret list-deleted --vault-name kv-platform-eastus
```

### Purge Protection
- **Purpose**: Prevent permanent deletion during retention period
- **When to use**: Production environments
- **Warning**: Cannot be disabled once enabled

## Network Security

### Default Deny with Exceptions

The module configures:
1. **Default Action**: Deny all traffic
2. **Bypass**: Allow Azure services (PaaS)
3. **Allowed IPs**: Whitelist admin IPs
4. **Allowed Subnets**: Whitelist application subnets

### Testing Access

```bash
# From allowed IP
az keyvault secret show --vault-name kv-platform-eastus --name MySecret

# From blocked IP (will fail)
# Error: Client address is not authorized
```

### Private Endpoint (Advanced)

For maximum security, use private endpoint:

```hcl
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-platform-eastus"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.hub_network.shared_services_subnet_id
  
  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = module.key_vault.key_vault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}
```

## Access Methods

### Azure CLI
```bash
# Set secret
az keyvault secret set \
  --vault-name kv-platform-eastus \
  --name "MySecret" \
  --value "MySecretValue"

# Get secret
az keyvault secret show \
  --vault-name kv-platform-eastus \
  --name "MySecret" \
  --query value -o tsv
```

### PowerShell
```powershell
# Set secret
Set-AzKeyVaultSecret `
  -VaultName "kv-platform-eastus" `
  -Name "MySecret" `
  -SecretValue (ConvertTo-SecureString "MySecretValue" -AsPlainText -Force)

# Get secret
(Get-AzKeyVaultSecret -VaultName "kv-platform-eastus" -Name "MySecret").SecretValueText
```

### Terraform
```hcl
# Store secret
resource "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  value        = "super-secret-value"
  key_vault_id = module.key_vault.key_vault_id
}

# Read secret
data "azurerm_key_vault_secret" "example" {
  name         = "my-secret"
  key_vault_id = module.key_vault.key_vault_id
}
```

### Application Code (C#)
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var client = new SecretClient(
    new Uri("https://kv-platform-eastus.vault.azure.net/"),
    new DefaultAzureCredential()
);

KeyVaultSecret secret = await client.GetSecretAsync("MySecret");
string value = secret.Value;
```

## Managed Identity Integration

### System-Assigned Identity
```hcl
resource "azurerm_app_service" "example" {
  # ...
  
  identity {
    type = "SystemAssigned"
  }
}

# Grant access to Key Vault
module "key_vault" {
  # ...
  
  access_policies = {
    app_service = {
      object_id = azurerm_app_service.example.identity[0].principal_id
      secret_permissions = ["Get", "List"]
    }
  }
}
```

### User-Assigned Identity
```hcl
resource "azurerm_user_assigned_identity" "example" {
  name                = "id-app-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_app_service" "example" {
  # ...
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.example.id]
  }
}

module "key_vault" {
  # ...
  
  access_policies = {
    app_identity = {
      object_id = azurerm_user_assigned_identity.example.principal_id
      secret_permissions = ["Get", "List"]
    }
  }
}
```

## Diagnostic Logging

When `log_analytics_workspace_id` is provided, diagnostic logs are enabled:

### Logged Events
- **AuditEvent**: All vault operations (read, write, delete)

### Query Audit Logs
```kql
AzureDiagnostics
| where ResourceType == "VAULTS"
| where OperationName == "SecretGet" or OperationName == "SecretSet"
| project TimeGenerated, OperationName, CallerIPAddress, ResultType, identity_claim_oid_g
| order by TimeGenerated desc
```

## Common Patterns

### Storing Connection Strings
```hcl
resource "azurerm_key_vault_secret" "sql_connection" {
  name         = "sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.example.fully_qualified_domain_name},1433;..."
  key_vault_id = module.key_vault.key_vault_id
}
```

### Storing API Keys
```hcl
resource "azurerm_key_vault_secret" "api_key" {
  name         = "external-api-key"
  value        = var.api_key  # From variable or output
  key_vault_id = module.key_vault.key_vault_id
}
```

### Certificate Storage
```hcl
resource "azurerm_key_vault_certificate" "cert" {
  name         = "imported-cert"
  key_vault_id = module.key_vault.key_vault_id
  
  certificate {
    contents = filebase64("path/to/certificate.pfx")
    password = var.cert_password
  }
}
```

## Best Practices

1. **Naming**: Use globally unique names (max 24 chars)
2. **Network ACLs**: Always deny by default in production
3. **Purge Protection**: Enable for production Key Vaults
4. **Soft Delete**: Use maximum retention (90 days) for production
5. **Access Policies**: Grant least privilege
6. **Managed Identities**: Prefer over service principal credentials
7. **Diagnostic Logs**: Always enable for audit trail
8. **Secrets Rotation**: Implement regular rotation for sensitive secrets
9. **Separate Vaults**: Use different vaults for different environments
10. **RBAC**: Consider Azure RBAC for Key Vault (preview)

## Security Considerations

1. **Never store Key Vault secrets in code or version control**
2. **Use separate Key Vaults per environment**
3. **Monitor access using diagnostic logs**
4. **Rotate secrets regularly**
5. **Use managed identities instead of storing credentials**
6. **Enable purge protection in production**
7. **Restrict network access**
8. **Audit access policies quarterly**

## Cost Considerations

| Item | Cost | Notes |
|------|------|-------|
| Key Vault | $0.03 per 10,000 operations | First 10k free |
| Secrets | Included | No per-secret cost |
| Keys (Software) | $0.03 per 10,000 operations | |
| Keys (HSM) | $1/key/month + operations | Premium SKU only |
| Certificate Operations | $3 per renewal | |

**Typical Monthly Cost**: $5-10 for most workloads

## Troubleshooting

### Error: Key Vault name already exists

Key Vault names are globally unique. If deleted with purge protection, it remains reserved:

```bash
# Check deleted vaults
az keyvault list-deleted

# Recover if needed
az keyvault recover --name kv-platform-eastus
```

### Error: Client address is not authorized

Your IP is not whitelisted:

```bash
# Add your IP
az keyvault network-rule add \
  --name kv-platform-eastus \
  --ip-address $(curl -s ifconfig.me)
```

### Error: Access denied

Check access policy:

```bash
# List access policies
az keyvault show --name kv-platform-eastus --query properties.accessPolicies
```

## Related Modules

- **management** - Provides Log Analytics for diagnostic logging
- **networking/hub** - Provides subnets for network ACLs
- **networking/spoke** - Provides application subnets for ACLs

## References

- [Azure Key Vault Overview](https://docs.microsoft.com/azure/key-vault/general/overview)
- [Key Vault Best Practices](https://docs.microsoft.com/azure/key-vault/general/best-practices)
- [Soft Delete Overview](https://docs.microsoft.com/azure/key-vault/general/soft-delete-overview)
- [Network Security](https://docs.microsoft.com/azure/key-vault/general/network-security)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)

## Changelog

### Version 1.1.0
- Added support for multiple access policies
- Added diagnostic logging integration
- Added network ACL configuration
- Added support for subnet whitelisting

### Version 1.0.0
- Initial release with basic Key Vault configuration
