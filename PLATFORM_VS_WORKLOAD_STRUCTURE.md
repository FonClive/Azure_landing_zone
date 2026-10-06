# Platform vs Workload - New Structure

## 🎯 Overview

The Azure Landing Zone now clearly separates **Platform (Shared)** resources from **Workload (Environment-specific)** resources.

## 📁 New Directory Structure

```
Azure_landing_zone/
│
├── environments/
│   │
│   ├── 00-platform/                    # 🏢 PLATFORM RESOURCES (Shared)
│   │   └── eastus/
│   │       ├── resource-groups/        # Platform resource groups
│   │       ├── connectivity/           # Hub VNet + Firewall
│   │       ├── management/             # Log Analytics + Automation
│   │       └── security/               # Platform Key Vault
│   │
│   └── 01-workloads/                   # 🎯 WORKLOAD RESOURCES (Per Environment)
│       ├── dev/
│       │   └── eastus/
│       │       ├── resource-groups/    # Dev resource groups
│       │       └── networking/         # Dev spoke VNet
│       │
│       ├── test/
│       │   └── eastus/
│       │       ├── resource-groups/    # Test resource groups
│       │       └── networking/         # Test spoke VNet
│       │
│       └── prod/
│           └── eastus/
│               ├── resource-groups/    # Prod resource groups
│               └── networking/         # Prod spoke VNet
│
├── terraform/modules/                  # Reusable modules (unchanged)
├── scripts/
│   ├── deploy-platform.ps1            # 🏢 Deploy platform resources
│   ├── deploy-workload.ps1            # 🎯 Deploy workload resources
│   ├── deploy.ps1                     # Legacy: Deploy everything
│   ├── validate.ps1
│   └── destroy.ps1
│
└── docs/
    ├── platform-vs-workload.md        # 📖 Detailed explanation
    └── ...
```

## 🏢 Platform Resources

### What They Are
- **Centrally managed** by the platform/cloud team
- **Shared across ALL environments** (dev, test, prod)
- **Stricter governance** and change management
- **Deployed once** and reused

### Resource Groups
```
rg-platform-connectivity-eastus    # Hub network, Firewall, VPN
rg-platform-management-eastus      # Log Analytics, Automation
rg-platform-security-eastus        # Platform Key Vault
rg-platform-dns-eastus             # Private DNS Zones
```

### Key Resources
| Resource | Purpose | Who Manages |
|----------|---------|-------------|
| Hub VNet (10.0.0.0/16) | Central connectivity | Platform Team |
| Azure Firewall | Traffic inspection | Platform Team |
| VPN Gateway | On-prem connectivity | Platform Team |
| Log Analytics | Centralized logging | Platform Team |
| Platform Key Vault | Platform secrets | Platform Team |
| Azure Policy | Governance | Platform Team |

### Deployment
```powershell
# Deploy platform resources (once per region)
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<sub-id>"
```

## 🎯 Workload Resources

### What They Are
- **Managed by application/workload teams**
- **Specific to each environment** (dev, test, prod)
- **Delegated permissions** via RBAC
- **Independent lifecycle** from platform

### Resource Groups (Per Environment)
```
# Development
rg-dev-networking-eastus           # Dev spoke VNet
rg-dev-shared-eastus               # Shared dev resources (ACR, Key Vault)
rg-dev-app1-eastus                 # Application 1 (dev)

# Production
rg-prod-networking-eastus          # Prod spoke VNet
rg-prod-shared-eastus              # Shared prod resources
rg-prod-app1-eastus                # Application 1 (prod)
```

### Key Resources
| Resource | Purpose | Who Manages |
|----------|---------|-------------|
| Dev Spoke (10.1.0.0/16) | Dev workload network | Dev Team |
| Prod Spoke (10.2.0.0/16) | Prod workload network | Prod Team |
| App Services | Applications | App Teams |
| SQL Databases | Data storage | App Teams |
| Workload Key Vaults | App secrets | App Teams |

### Deployment
```powershell
# Deploy dev environment
.\scripts\deploy-workload.ps1 -Environment dev -Region eastus -SubscriptionId "<sub-id>"

# Deploy prod environment
.\scripts\deploy-workload.ps1 -Environment prod -Region eastus -SubscriptionId "<sub-id>"
```

## 🔄 Deployment Flow

### Step 1: Deploy Platform (Once)
```powershell
# Deploy shared platform resources
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<sub-id>"
```

**This creates:**
- ✅ Platform resource groups
- ✅ Hub VNet with Azure Firewall
- ✅ Log Analytics workspace
- ✅ Platform Key Vault
- ✅ Shared management infrastructure

### Step 2: Deploy Workloads (Per Environment)
```powershell
# Deploy dev environment
.\scripts\deploy-workload.ps1 -Environment dev -Region eastus -SubscriptionId "<sub-id>"

# Deploy test environment
.\scripts\deploy-workload.ps1 -Environment test -Region eastus -SubscriptionId "<sub-id>"

# Deploy prod environment
.\scripts\deploy-workload.ps1 -Environment prod -Region eastus -SubscriptionId "<sub-id>"
```

**Each creates:**
- ✅ Environment-specific resource groups
- ✅ Spoke VNet peered to hub
- ✅ Subnets with NSGs
- ✅ Route tables to firewall

## 🏷️ Tagging Strategy

### Platform Resources
```hcl
tags = {
  Tier        = "Platform"
  Component   = "Connectivity|Management|Security"
  Owner       = "PlatformTeam"
  ManagedBy   = "Terragrunt"
}
```

### Workload Resources
```hcl
tags = {
  Tier        = "Workload"
  Environment = "Development|Test|Production"
  Component   = "Networking|Application"
  Owner       = "DevTeam|ProdTeam"
  ManagedBy   = "Terragrunt"
}
```

## 🔐 RBAC Model

### Platform Resources
| Role | Scope | Assigned To |
|------|-------|-------------|
| Owner | `rg-platform-*` | Platform Team |
| Network Contributor | Hub VNet | Network Team |
| Reader | All platform RGs | All Teams |

### Workload Resources
| Role | Scope | Assigned To |
|------|-------|-------------|
| Contributor | `rg-dev-*` | Dev Team |
| Contributor | `rg-test-*` | Test Team |
| Contributor (limited) | `rg-prod-*` | Prod Team |
| Owner | All workload RGs | Platform Team |

## 💾 State Management

### Platform State
```
Storage Account: stplatformtfstate
Container: tfstate
Key Pattern: platform/{region}/{component}/terraform.tfstate

Examples:
- platform/eastus/resource-groups/terraform.tfstate
- platform/eastus/connectivity/terraform.tfstate
- platform/eastus/management/terraform.tfstate
```

### Workload State
```
Storage Account: stworkloadtfstate
Container: tfstate
Key Pattern: workloads/{env}/{region}/{component}/terraform.tfstate

Examples:
- workloads/dev/eastus/resource-groups/terraform.tfstate
- workloads/dev/eastus/networking/terraform.tfstate
- workloads/prod/eastus/resource-groups/terraform.tfstate
- workloads/prod/eastus/networking/terraform.tfstate
```

## 📊 Visual Architecture

```
┌─────────────────────────────────────────────────────────┐
│              🏢 PLATFORM LAYER (Shared)                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Hub VNet (10.0.0.0/16)                     │ │
│  │  - Azure Firewall                                  │ │
│  │  - VPN Gateway                                     │ │
│  │  - Bastion                                         │ │
│  └──────────────┬─────────────────────────────────────┘ │
│                 │                                        │
│  ┌──────────────┴─────────────────────────────────────┐ │
│  │  Management: Log Analytics, Automation, Policy     │ │
│  └────────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┴────────────┬────────────────┐
        │                         │                │
┌───────▼─────────┐    ┌─────────▼────────┐  ┌───▼────────────┐
│ 🎯 DEV WORKLOAD │    │ 🎯 TEST WORKLOAD │  │ 🎯 PROD WORKLOAD│
│                 │    │                  │  │                │
│ Spoke: 10.1/16  │    │ Spoke: 10.3/16   │  │ Spoke: 10.2/16 │
│ - App Subnet    │    │ - App Subnet     │  │ - App Subnet   │
│ - Data Subnet   │    │ - Data Subnet    │  │ - Data Subnet  │
│ - Integration   │    │ - Integration    │  │ - Integration  │
│                 │    │                  │  │                │
│ Managed by:     │    │ Managed by:      │  │ Managed by:    │
│ Dev Team        │    │ Test Team        │  │ Prod Team      │
└─────────────────┘    └──────────────────┘  └────────────────┘
```

## 🎁 Benefits

### 1. Clear Ownership
- ✅ Platform team owns shared infrastructure
- ✅ App teams own their workload resources
- ✅ No confusion about responsibilities

### 2. Better Security
- ✅ Platform resources are locked down
- ✅ Workload teams have delegated access
- ✅ Separate RBAC per tier

### 3. Independent Scaling
- ✅ Platform changes don't affect workloads
- ✅ Each environment scales independently
- ✅ Dev changes don't impact prod

### 4. Cost Tracking
- ✅ Platform costs clearly separated
- ✅ Per-environment cost allocation
- ✅ Per-application cost tracking

### 5. Governance
- ✅ Stricter policies on platform
- ✅ Flexible policies on workloads
- ✅ Different change management processes

## 📝 Quick Commands

### Deploy Everything
```powershell
# 1. Deploy platform (once)
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<sub-id>"

# 2. Deploy dev workload
.\scripts\deploy-workload.ps1 -Environment dev -Region eastus -SubscriptionId "<sub-id>"

# 3. Deploy prod workload
.\scripts\deploy-workload.ps1 -Environment prod -Region eastus -SubscriptionId "<sub-id>"
```

### Validation
```powershell
# Validate platform
cd environments/00-platform/eastus
terragrunt run-all validate

# Validate workload
cd environments/01-workloads/prod/eastus
terragrunt run-all validate
```

### List Resources
```powershell
# Platform resources
az resource list --query "[?tags.Tier=='Platform'].{Name:name, Type:type, RG:resourceGroup}" -o table

# Workload resources
az resource list --query "[?tags.Tier=='Workload'].{Name:name, Type:type, Env:tags.Environment, RG:resourceGroup}" -o table
```

## 🔄 Migration from Old Structure

If you have the old structure deployed:

### Option 1: Start Fresh (Recommended)
1. Deploy new structure to separate subscription
2. Migrate applications gradually
3. Decomission old structure

### Option 2: In-Place Migration
1. Use `terraform state mv` to reorganize state
2. Update resource tags
3. Update RBAC assignments

## 📚 Related Documentation

- [Platform vs Workload - Detailed](docs/platform-vs-workload.md)
- [Architecture](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Operations Guide](docs/operations-guide.md)

## ✅ What Changed

### Old Structure (Mixed)
```
environments/prod/eastus/
├── resource-groups/          # ⚠️ Mixed
├── management/               # ✅ Platform
├── network-hub/              # ✅ Platform
├── network-spoke-dev/        # ❌ Should be in dev
├── network-spoke-prod/       # ❌ Should be in prod
└── security/                 # ⚠️ Mixed
```

### New Structure (Separated)
```
environments/
├── 00-platform/eastus/       # ✅ All platform resources
│   ├── resource-groups/
│   ├── connectivity/
│   ├── management/
│   └── security/
│
└── 01-workloads/             # ✅ Per-environment resources
    ├── dev/eastus/
    ├── test/eastus/
    └── prod/eastus/
```

## 🎉 Result

You now have a **clear, scalable, and maintainable** Azure Landing Zone that:
- ✅ Separates platform from workload concerns
- ✅ Enables team autonomy
- ✅ Follows Azure best practices
- ✅ Scales easily to multiple environments and regions
- ✅ Provides clear cost allocation
- ✅ Implements proper governance
