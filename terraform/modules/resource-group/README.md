# Resource Group Module

## Overview

This module creates and manages multiple Azure Resource Groups with optional management locks. It's designed to support the creation of both platform and workload resource groups with consistent tagging and security controls.

## Features

- ✅ Create multiple resource groups in a single module call
- ✅ Optional management locks (CanNotDelete, ReadOnly)
- ✅ Flexible tagging with common and per-resource group tags
- ✅ Support for different lock levels per resource group

## Usage

### Basic Example

```hcl
module "resource_groups" {
  source = "../../modules/resource-group"

  resource_groups = {
    connectivity = {
      resource_group_name = "rg-platform-connectivity-eastus"
      location            = "eastus"
    }
    management = {
      resource_group_name = "rg-platform-management-eastus"
      location            = "eastus"
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Example with Locks

```hcl
module "platform_resource_groups" {
  source = "../../modules/resource-group"

  resource_groups = {
    connectivity = {
      resource_group_name = "rg-platform-connectivity-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      lock_notes          = "Platform connectivity - contact platform team"
      additional_tags = {
        Tier      = "Platform"
        Component = "Connectivity"
      }
    }
    management = {
      resource_group_name = "rg-platform-management-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      additional_tags = {
        Tier      = "Platform"
        Component = "Management"
      }
    }
    workload_dev = {
      resource_group_name = "rg-dev-networking-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags = {
        Environment = "Development"
        Tier        = "Workload"
      }
    }
  }

  tags = {
    ManagedBy  = "Terraform"
    Repository = "Azure_landing_zone"
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
| resource_groups | Map of resource groups to create | `map(object)` | n/a | yes |
| tags | Common tags to apply to all resource groups | `map(string)` | `{}` | no |

### resource_groups Object Structure

```hcl
resource_groups = {
  key = {
    resource_group_name = string           # Required: Name of the resource group
    location            = string           # Required: Azure region
    lock_level          = string           # Optional: "CanNotDelete", "ReadOnly", or "None"
    lock_notes          = string           # Optional: Notes for the lock
    additional_tags     = map(string)      # Optional: Resource-specific tags
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| resource_group_names | Map of resource group names indexed by key |
| resource_group_ids | Map of resource group IDs indexed by key |
| hub_rg_name | Hub resource group name (if "hub" key exists) |
| management_rg_name | Management resource group name (if "management" key exists) |
| security_rg_name | Security resource group name (if "security" key exists) |

## Output Examples

```hcl
# Access specific resource group
resource_group_name = module.resource_groups.resource_group_names["connectivity"]

# Use in other modules
resource_group_name = module.resource_groups.management_rg_name
```

## Lock Levels

### CanNotDelete
- Users can read and modify resources
- Cannot delete the resource group or resources within it
- Recommended for: Production and platform resource groups

### ReadOnly
- Users can read resources
- Cannot modify or delete resources
- Recommended for: Archived or compliance-sensitive resources

### None (Default)
- No lock applied
- Full permissions based on RBAC
- Recommended for: Development and testing resource groups

## Tagging Strategy

Tags are merged in the following order (later tags override earlier ones):
1. Common tags (applied to all)
2. Additional tags (per resource group)

```hcl
# Common tags
tags = {
  ManagedBy = "Terraform"
  CostCenter = "IT"
}

# Additional tags per resource group
additional_tags = {
  Tier = "Platform"
  Component = "Connectivity"
}

# Resulting tags
{
  ManagedBy = "Terraform"
  CostCenter = "IT"
  Tier = "Platform"
  Component = "Connectivity"
}
```

## Best Practices

1. **Use Descriptive Keys**: Use meaningful keys like `connectivity`, `management`, `workload_prod`
2. **Apply Locks Appropriately**: Lock production and platform resource groups
3. **Consistent Tagging**: Use common tags for organization-wide standards
4. **Regional Grouping**: Include region in resource group name for clarity
5. **Purpose in Name**: Make the purpose clear in the name

## Examples by Use Case

### Platform Resource Groups

```hcl
module "platform_rgs" {
  source = "../../modules/resource-group"

  resource_groups = {
    connectivity = {
      resource_group_name = "rg-platform-connectivity-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      additional_tags     = { Component = "Connectivity" }
    }
    management = {
      resource_group_name = "rg-platform-management-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      additional_tags     = { Component = "Management" }
    }
    security = {
      resource_group_name = "rg-platform-security-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      additional_tags     = { Component = "Security" }
    }
  }

  tags = {
    Tier      = "Platform"
    ManagedBy = "Terraform"
  }
}
```

### Workload Resource Groups

```hcl
module "dev_rgs" {
  source = "../../modules/resource-group"

  resource_groups = {
    networking = {
      resource_group_name = "rg-dev-networking-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags     = { Component = "Networking" }
    }
    shared = {
      resource_group_name = "rg-dev-shared-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags     = { Component = "Shared" }
    }
    app1 = {
      resource_group_name = "rg-dev-app1-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags     = { 
        Component   = "Application"
        Application = "App1"
      }
    }
  }

  tags = {
    Environment = "Development"
    Tier        = "Workload"
    ManagedBy   = "Terraform"
  }
}
```

## Removing Locks

To remove a lock from an existing resource group:

1. Change `lock_level` to `"None"`
2. Run `terraform apply`
3. The lock will be removed automatically

## Troubleshooting

### Error: Cannot delete resource group

**Cause**: Resource group has a lock or contains resources

**Solution**:
```bash
# Check for locks
az lock list --resource-group <rg-name>

# Remove lock if needed
az lock delete --name <lock-name> --resource-group <rg-name>

# Ensure all resources are deleted first
az resource list --resource-group <rg-name>
```

### Error: Lock already exists

**Cause**: Lock was created outside Terraform

**Solution**:
```bash
# Import existing lock
terraform import 'module.resource_groups.azurerm_management_lock.rg_lock["key"]' /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.Authorization/locks/{lock-name}
```

## Security Considerations

1. **Lock Production Resources**: Always lock production and platform resource groups
2. **RBAC**: Use Azure RBAC to control who can create/remove locks
3. **Audit**: Monitor lock changes using Azure Activity Log
4. **Documentation**: Document lock policies in `lock_notes`

## Cost Considerations

Resource groups themselves have no cost. Costs are incurred by resources within them.

Use tags for cost allocation:
```hcl
tags = {
  CostCenter  = "IT-Infrastructure"
  Environment = "Production"
  Project     = "LandingZone"
}
```

## Related Modules

- **networking/hub** - Uses platform resource groups
- **networking/spoke** - Uses workload resource groups
- **management** - Requires management resource group
- **security/key-vault** - Requires security resource group

## References

- [Azure Resource Groups](https://docs.microsoft.com/azure/azure-resource-manager/management/overview#resource-groups)
- [Azure Management Locks](https://docs.microsoft.com/azure/azure-resource-manager/management/lock-resources)
- [Resource Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

## Changelog

### Version 1.1.0
- Added support for multiple resource groups in single call
- Added optional management locks
- Added per-resource group tagging

### Version 1.0.0
- Initial release
