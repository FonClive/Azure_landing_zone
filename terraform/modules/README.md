# Terraform Modules Documentation

## Overview

This directory contains reusable Terraform modules for deploying Azure Landing Zone infrastructure. Each module is self-contained, well-documented, and follows Azure best practices.

## Available Modules

| Module | Purpose | Documentation |
|--------|---------|---------------|
| **resource-group** | Create and manage resource groups with optional locks | [README](resource-group/README.md) |
| **networking/hub** | Deploy hub virtual network with firewall | [README](networking/hub/README.md) |
| **networking/spoke** | Deploy spoke virtual networks with peering | [README](networking/spoke/README.md) |
| **management** | Deploy Log Analytics, Automation, and monitoring | [README](management/README.md) |
| **security/key-vault** | Deploy Azure Key Vault with security features | [README](security/key-vault/README.md) |

## Module Structure

Each module follows a consistent structure:

```
module-name/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Comprehensive documentation
```

## Quick Start

### 1. Resource Groups

Create multiple resource groups with optional management locks:

```hcl
module "resource_groups" {
  source = "./modules/resource-group"

  resource_groups = {
    connectivity = {
      resource_group_name = "rg-platform-connectivity-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
    }
    management = {
      resource_group_name = "rg-platform-management-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
    }
  }
  
  tags = {
    ManagedBy = "Terraform"
  }
}
```

[Full Documentation →](resource-group/README.md)

### 2. Hub Network

Deploy centralized hub network with Azure Firewall:

```hcl
module "hub_network" {
  source = "./modules/networking/hub"

  vnet_name           = "vnet-platform-hub-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-connectivity-eastus"
  address_space       = ["10.0.0.0/16"]
  
  firewall_subnet_prefix        = ["10.0.1.0/26"]
  shared_services_subnet_prefix = ["10.0.10.0/24"]
  
  enable_firewall = true
  firewall_sku_tier = "Standard"
  
  tags = {
    Tier = "Platform"
  }
}
```

[Full Documentation →](networking/hub/README.md)

### 3. Spoke Network

Deploy workload spoke networks:

```hcl
module "spoke_network" {
  source = "./modules/networking/spoke"

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
  
  # Connect to hub
  hub_vnet_id = module.hub_network.vnet_id
  hub_vnet_name = module.hub_network.vnet_name
  hub_resource_group_name = "rg-platform-connectivity-eastus"
  firewall_private_ip = module.hub_network.firewall_private_ip
  route_to_firewall = true
  
  tags = {
    Environment = "Development"
  }
}
```

[Full Documentation →](networking/spoke/README.md)

### 4. Management & Monitoring

Deploy centralized monitoring infrastructure:

```hcl
module "management" {
  source = "./modules/management"

  log_analytics_name       = "law-platform-eastus"
  location                 = "eastus"
  resource_group_name      = "rg-platform-management-eastus"
  retention_in_days        = 90
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
    Tier = "Platform"
  }
}
```

[Full Documentation →](management/README.md)

### 5. Key Vault

Deploy secure secrets management:

```hcl
module "key_vault" {
  source = "./modules/security/key-vault"

  key_vault_name      = "kv-platform-eastus"
  location            = "eastus"
  resource_group_name = "rg-platform-security-eastus"
  
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  
  default_network_acl_action = "Deny"
  allowed_ip_ranges = ["203.0.113.0/24"]
  
  access_policies = {
    admin = {
      object_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      secret_permissions = ["Get", "List", "Set", "Delete"]
    }
  }
  
  log_analytics_workspace_id = module.management.log_analytics_workspace_id
  
  tags = {
    Tier = "Platform"
  }
}
```

[Full Documentation →](security/key-vault/README.md)

## Module Dependencies

```
                    ┌─────────────────┐
                    │ resource-group  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
      ┌─────────────┐  ┌──────────┐  ┌──────────┐
      │ management  │  │ hub      │  │ security │
      └─────────────┘  │ network  │  │/key-vault│
                       └────┬─────┘  └──────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ spoke        │
                    │ network      │
                    └──────────────┘
```

### Deployment Order

1. **resource-group** - Creates all resource groups
2. **management** - Sets up Log Analytics (no dependencies)
3. **hub network** - Creates hub VNet (depends on resource-group)
4. **spoke network** - Creates spoke VNets (depends on hub network)
5. **key-vault** - Creates Key Vault (depends on management for logging)

## Common Patterns

### Platform Infrastructure

```hcl
# 1. Create resource groups
module "platform_rgs" {
  source = "./modules/resource-group"
  # ... platform resource groups ...
}

# 2. Set up monitoring
module "management" {
  source = "./modules/management"
  # ... depends on platform_rgs ...
}

# 3. Create hub network
module "hub" {
  source = "./modules/networking/hub"
  # ... depends on platform_rgs ...
}

# 4. Create platform Key Vault
module "platform_kv" {
  source = "./modules/security/key-vault"
  # ... depends on platform_rgs and management ...
}
```

### Workload Infrastructure

```hcl
# 1. Create workload resource groups
module "dev_rgs" {
  source = "./modules/resource-group"
  # ... dev resource groups ...
}

# 2. Create spoke network
module "dev_spoke" {
  source = "./modules/networking/spoke"
  # ... depends on hub and dev_rgs ...
}

# 3. Create workload Key Vault
module "dev_kv" {
  source = "./modules/security/key-vault"
  # ... depends on dev_rgs ...
}
```

## Module Features

### Reusability
- ✅ All modules are environment-agnostic
- ✅ Configurable through input variables
- ✅ No hard-coded values

### Security
- ✅ Network security enabled by default
- ✅ Diagnostic logging supported
- ✅ RBAC-ready configurations
- ✅ Follow least-privilege principles

### Standards
- ✅ Consistent naming conventions
- ✅ Comprehensive tagging support
- ✅ Azure best practices implemented
- ✅ Production-ready configurations

### Documentation
- ✅ Complete README for each module
- ✅ Usage examples (basic and advanced)
- ✅ Input/output reference tables
- ✅ Troubleshooting guides

## Best Practices

### Module Usage

1. **Always specify versions** in module sources
2. **Use outputs** to pass data between modules
3. **Apply tags consistently** across all modules
4. **Document customizations** in your root module

### Development

1. **Test modules independently** before integration
2. **Use terraform validate** before committing
3. **Version control** all modules
4. **Document breaking changes** in changelog

### Naming

Follow Azure naming conventions:

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-{purpose}-{env}-{region}` | `rg-platform-connectivity-eastus` |
| VNet | `vnet-{purpose}-{env}-{region}` | `vnet-hub-prod-eastus` |
| Subnet | `snet-{purpose}` | `snet-app` |
| Key Vault | `kv-{env}-{region}-{num}` | `kv-prod-eastus-001` |
| Log Analytics | `law-{env}-{region}` | `law-platform-eastus` |

## Testing Modules

### Validate Syntax
```bash
cd modules/resource-group
terraform init
terraform validate
```

### Format Code
```bash
terraform fmt -recursive
```

### Plan Changes
```bash
terraform plan -out=tfplan
```

## Contributing

When adding or modifying modules:

1. **Follow the structure**: main.tf, variables.tf, outputs.tf, README.md
2. **Document thoroughly**: Every variable and output
3. **Add examples**: Basic and advanced usage
4. **Test completely**: Validate, plan, and apply
5. **Update changelog**: Document changes in README

## Module Versioning

Modules use semantic versioning:

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes

## Support

For module-specific questions:
- Check the module's README.md
- Review examples in the documentation
- Check Terraform documentation
- Consult Azure documentation

## Resources

- [Terraform Module Documentation](https://www.terraform.io/docs/language/modules/index.html)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Landing Zone Best Practices](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

## Module Changelog

### All Modules v1.1.0 (Current)
- Enhanced documentation with comprehensive READMEs
- Added troubleshooting sections
- Expanded examples with real-world scenarios
- Added cost considerations

### All Modules v1.0.0
- Initial release of all modules
- Basic functionality implemented
- Core documentation provided
