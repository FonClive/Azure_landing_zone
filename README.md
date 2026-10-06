# Azure Landing Zone - Single Subscription Deployment

This repository contains Infrastructure as Code (IaC) for deploying an Azure Landing Zone using **OpenTofu** and **Terragrunt** in a single subscription model.

> **Note**: This project uses [OpenTofu](https://opentofu.org/) (open-source Terraform fork) instead of Terraform. See [OPENTOFU_SETUP.md](OPENTOFU_SETUP.md) for details.

## 🏗️ Architecture Overview

This landing zone implements the following structure:
- **Hub-Spoke Network Topology**: Central hub for shared services with spoke networks for workloads
- **Management & Governance**: Centralized logging, monitoring, and policy enforcement
- **Security**: Azure Firewall, NSGs, Key Vault, and RBAC controls
- **Connectivity**: Azure Firewall with VPN Gateway and ExpressRoute ready architecture

### Network Design
```
Hub VNet (10.0.0.0/16)
├── Azure Firewall (10.0.1.0/26)
├── Gateway Subnet (10.0.0.0/27)
├── Bastion Subnet (10.0.2.0/27)
└── Shared Services (10.0.10.0/24)
    │
    ├─── Dev Spoke (10.1.0.0/16)
    │    ├── App Subnet (10.1.1.0/24)
    │    ├── Data Subnet (10.1.2.0/24)
    │    └── Integration Subnet (10.1.3.0/24)
    │
    └─── Prod Spoke (10.2.0.0/16)
         ├── App Subnet (10.2.1.0/24)
         ├── Data Subnet (10.2.2.0/24)
         └── Integration Subnet (10.2.3.0/24)
```

## 📋 Prerequisites

### Required Tools
- **Azure CLI** >= 2.50.0 - [Install](https://docs.microsoft.com/cli/azure/install-azure-cli)
- **OpenTofu** >= 1.6.0 - [Install](https://opentofu.org/docs/intro/install/)
- **Terragrunt** >= 0.50.0 - [Install](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- **PowerShell** >= 7.0 - [Install](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)

### Azure Permissions
- Owner or Contributor + User Access Administrator role on the target subscription
- Ability to create resource groups and service principals

## 🚀 Quick Start

### 1. Clone and Configure
```powershell
# Clone the repository
git clone <repository-url>
cd Azure_landing_zone

# Login to Azure
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Customize Configuration
```powershell
# Review platform configuration
# Edit files in: environments/00-platform/eastus/*/terragrunt.hcl

# Key files to customize:
# - connectivity/terragrunt.hcl - Hub network, firewall settings
# - management/terragrunt.hcl - Alert email addresses
# - security/terragrunt.hcl - Platform Key Vault name (must be unique)

# Review workload configurations
# Edit files in: environments/01-workloads/{env}/eastus/*/terragrunt.hcl
```

### 3. Deploy Platform Resources (Once)
```powershell
# Deploy shared platform infrastructure
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<your-sub-id>"

# Preview changes first (recommended)
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<your-sub-id>" -WhatIf
```

### 4. Deploy Workload Environments
```powershell
# Deploy dev environment
.\scripts\deploy-workload.ps1 -Environment dev -Region eastus -SubscriptionId "<your-sub-id>"

# Deploy prod environment
.\scripts\deploy-workload.ps1 -Environment prod -Region eastus -SubscriptionId "<your-sub-id>"
```

### 5. Validate Deployment
```powershell
# Run validation checks
.\scripts\validate.ps1
```

## 📁 Project Structure

The project **separates Platform (Shared) resources from Workload (Environment-specific) resources**:

```
Azure_landing_zone/
│
├── environments/
│   ├── 00-platform/               # 🏢 PLATFORM (Shared Resources)
│   │   └── eastus/
│   │       ├── connectivity/      # Hub VNet + Firewall
│   │       ├── management/        # Log Analytics + Automation
│   │       └── security/          # Platform Key Vault
│   │
│   └── 01-workloads/              # 🎯 WORKLOADS (Per Environment)
│       ├── dev/eastus/            # Development environment
│       │   ├── resource-groups/
│       │   └── networking/        # Dev spoke VNet
│       ├── test/eastus/           # Test environment (ready to add)
│       └── prod/eastus/           # Production environment
│           ├── resource-groups/
│           └── networking/        # Prod spoke VNet
│
├── terraform/modules/             # 🔧 Reusable Terraform modules
│   ├── resource-group/
│   ├── networking/ (hub/spoke)
│   ├── management/
│   └── security/
│
├── scripts/                       # 🔨 Deployment scripts
│   ├── deploy-platform.ps1        # 🏢 Deploy platform resources
│   ├── deploy-workload.ps1        # 🎯 Deploy workload resources
│   ├── validate.ps1
│   └── destroy.ps1
│
├── docs/                          # 📚 Documentation
│   ├── platform-vs-workload.md    # 🆕 Platform vs Workload guide
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── ...
│
└── policies/                      # 📜 Azure Policy definitions
```

**Key Distinction:**
- **🏢 Platform**: Shared infrastructure (Hub, Firewall, Monitoring) - deployed once
- **🎯 Workloads**: Per-environment resources (Spokes, Apps) - deployed per env

See [PLATFORM_VS_WORKLOAD_STRUCTURE.md](PLATFORM_VS_WORKLOAD_STRUCTURE.md) for detailed explanation.

## ⚠️ Important: Use Only the New Structure

The project uses a **Platform vs Workload** separation. There is no `environments/prod/` folder - instead:
- **Platform resources** → `environments/00-platform/`
- **Workload resources** → `environments/01-workloads/{env}/`

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for details.

## 🔄 Deployment Order

The structure now separates platform and workload deployments:

### Phase 1: Platform Resources (Deploy Once)
1. **Platform Resource Groups** - Foundation for platform infrastructure
2. **Management** - Log Analytics, Automation Account, Storage
3. **Connectivity** - Hub VNet with Azure Firewall
4. **Security** - Platform Key Vault and access policies

**Deploy with:**
```powershell
.\scripts\deploy-platform.ps1 -Region eastus -SubscriptionId "<sub-id>"
```

### Phase 2: Workload Resources (Per Environment)
1. **Workload Resource Groups** - Per-environment resource groups
2. **Networking** - Spoke VNets peered to hub

**Deploy with:**
```powershell
# Dev environment
.\scripts\deploy-workload.ps1 -Environment dev -Region eastus -SubscriptionId "<sub-id>"

# Prod environment
.\scripts\deploy-workload.ps1 -Environment prod -Region eastus -SubscriptionId "<sub-id>"
```

**Why This Order?**
- Platform resources are shared and must exist first
- Workload spokes depend on platform hub for connectivity
- Workload resources log to platform Log Analytics

## 🛠️ Core Components

### Networking
- **Hub Virtual Network**: Centralized connectivity with Azure Firewall
- **Spoke Virtual Networks**: Isolated workload environments
- **VNet Peering**: Hub-spoke connectivity
- **Route Tables**: Force traffic through Azure Firewall
- **NSGs**: Subnet-level security

### Management & Monitoring
- **Log Analytics Workspace**: Centralized logging (90-day retention)
- **Azure Automation**: Update management and change tracking
- **Storage Account**: Long-term diagnostic logs
- **Action Groups**: Alert notifications
- **Solutions**: Security, Updates, ChangeTracking, VMInsights

### Security
- **Azure Firewall**: Network and application traffic filtering
- **Key Vault**: Secrets management with network ACLs
- **Azure Policy**: Compliance and governance
- **RBAC**: Role-based access control
- **Diagnostic Logging**: All resources log to Log Analytics

### Governance
- **Naming Conventions**: Enforced via Azure Policy
- **Resource Tagging**: Required tags policy
- **Resource Locks**: Protection for critical resources
- **Cost Management**: Resource tagging for cost allocation

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | Detailed architecture design and component descriptions |
| [Deployment Guide](docs/deployment-guide.md) | Step-by-step deployment instructions and troubleshooting |
| [Naming Conventions](docs/naming-conventions.md) | Resource naming standards and tagging strategy |
| [Operations Guide](docs/operations-guide.md) | Daily operations, maintenance, and incident response |
| [Contributing](CONTRIBUTING.md) | Guidelines for contributing to this project |
| [Project Structure](PROJECT_STRUCTURE.md) | Complete file structure documentation |

## ⚙️ Manual Deployment

If you prefer manual deployment over the automated script:

```powershell
# 1. Deploy resource groups
cd environments/prod/eastus/resource-groups
terragrunt init
terragrunt plan
terragrunt apply

# 2. Deploy management
cd ../management
terragrunt init && terragrunt apply

# 3. Deploy hub network
cd ../network-hub
terragrunt init && terragrunt apply

# 4. Deploy spoke networks
cd ../network-spoke-dev
terragrunt init && terragrunt apply

cd ../network-spoke-prod
terragrunt init && terragrunt apply

# 5. Deploy security
cd ../security
terragrunt init && terragrunt apply
```

## 🧪 Testing & Validation

### Run Validation
```powershell
.\scripts\validate.ps1 -Environment prod
```

### Manual Verification
```powershell
# Check resource groups
az group list --output table

# Check virtual networks
az network vnet list --output table

# Check VNet peerings
az network vnet peering list `
  --resource-group rg-network-hub-prod-eastus `
  --vnet-name vnet-hub-prod-eastus --output table

# Check firewall status
az network firewall show `
  --name afw-vnet-hub-prod-eastus `
  --resource-group rg-network-hub-prod-eastus
```

## 🗑️ Cleanup

To destroy all resources:

```powershell
.\scripts\destroy.ps1 -Environment prod -Region eastus -SubscriptionId "<your-sub-id>"
```

**⚠️ Warning**: This permanently deletes all resources. Type 'DELETE' when prompted to confirm.

## 🔐 Security Considerations

- All sensitive files (`.tfvars`, state files, secrets) are excluded via `.gitignore`
- Terraform state is stored remotely in Azure Storage with versioning
- Key Vault uses network ACLs (deny by default)
- Azure Firewall inspects all spoke-to-internet traffic
- NSGs applied to all subnets
- Diagnostic logging enabled on all resources

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
1. Check the [documentation](docs/)
2. Review [troubleshooting guide](docs/deployment-guide.md#troubleshooting)
3. Open an issue in the repository

## 🔗 Related Resources

- [Azure Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Azure Naming Conventions](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)

## 📊 Project Status

- ✅ Hub-Spoke network topology
- ✅ Azure Firewall integration
- ✅ Management and monitoring
- ✅ Security (Key Vault)
- ✅ Azure Policy definitions
- ✅ Automated deployment scripts
- ✅ Comprehensive documentation
- ⏳ CI/CD pipelines (coming soon)
- ⏳ Multi-region support (coming soon)
