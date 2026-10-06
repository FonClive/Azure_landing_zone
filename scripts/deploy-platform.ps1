#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Platform (Shared) Resources

.DESCRIPTION
    This script deploys the platform/shared resources that are used by all workloads.
    These are centrally managed and should be deployed first.

.PARAMETER Region
    The Azure region to deploy to (e.g., eastus, westus2)

.PARAMETER SubscriptionId
    Azure subscription ID to deploy to

.PARAMETER WhatIf
    Preview changes without applying them

.EXAMPLE
    .\deploy-platform.ps1 -Region eastus -SubscriptionId "xxxx-xxxx-xxxx"

.EXAMPLE
    .\deploy-platform.ps1 -Region eastus -SubscriptionId "xxxx-xxxx-xxxx" -WhatIf
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('eastus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Region,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$PlatformPath = Join-Path $ScriptRoot "environments\00-platform\$Region"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "🏢 Platform Resources Deployment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Yellow
Write-Host "Type: Platform (Shared)" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`n📋 Checking prerequisites..." -ForegroundColor Green

$checks = @(
    @{ Name = "Azure CLI"; Command = "az version" },
    @{ Name = "OpenTofu"; Command = "tofu version" },
    @{ Name = "Terragrunt"; Command = "terragrunt --version" }
)

foreach ($check in $checks) {
    try {
        Invoke-Expression $check.Command | Out-Null
        Write-Host "✓ $($check.Name) installed" -ForegroundColor Green
    } catch {
        Write-Error "$($check.Name) is not installed"
        exit 1
    }
}

# Azure login
Write-Host "`n🔐 Checking Azure authentication..." -ForegroundColor Green
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Not logged in. Initiating Azure login..." -ForegroundColor Yellow
    az login
}

az account set --subscription $SubscriptionId
$currentSub = az account show | ConvertFrom-Json
Write-Host "✓ Using subscription: $($currentSub.name)" -ForegroundColor Green

# Create state storage
Write-Host "`n💾 Setting up Terraform state storage..." -ForegroundColor Green
$stateRgName = "rg-terraform-state-platform"
$stateStorageName = "stplatformtfstate"
$stateContainerName = "tfstate"

$stateRgExists = az group exists --name $stateRgName
if ($stateRgExists -eq 'false') {
    Write-Host "Creating state resource group: $stateRgName" -ForegroundColor Yellow
    az group create --name $stateRgName --location $Region --tags Tier=Platform ManagedBy=Script Purpose=TerraformState
}

$stateStorageExists = az storage account check-name --name $stateStorageName --query 'nameAvailable' -o tsv
if ($stateStorageExists -eq 'true') {
    Write-Host "Creating state storage account: $stateStorageName" -ForegroundColor Yellow
    az storage account create `
        --name $stateStorageName `
        --resource-group $stateRgName `
        --location $Region `
        --sku Standard_GRS `
        --encryption-services blob `
        --tags Tier=Platform ManagedBy=Script Purpose=TerraformState
    
    az storage account blob-service-properties update `
        --account-name $stateStorageName `
        --resource-group $stateRgName `
        --enable-versioning true
}

$containerExists = az storage container exists --name $stateContainerName --account-name $stateStorageName --query 'exists' -o tsv
if ($containerExists -eq 'false') {
    Write-Host "Creating state container: $stateContainerName" -ForegroundColor Yellow
    az storage container create `
        --name $stateContainerName `
        --account-name $stateStorageName `
        --auth-mode login
}

Write-Host "✓ State storage configured" -ForegroundColor Green

# Platform deployment order
$deploymentOrder = @(
    @{ Name = "resource-groups"; Description = "Platform resource groups" },
    @{ Name = "management"; Description = "Management and monitoring" },
    @{ Name = "connectivity"; Description = "Hub network and firewall" },
    @{ Name = "security"; Description = "Platform security (Key Vault)" }
)

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "🗂️  Platform Deployment Order:" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
for ($i = 0; $i -lt $deploymentOrder.Length; $i++) {
    Write-Host "$($i + 1). $($deploymentOrder[$i].Name) - $($deploymentOrder[$i].Description)" -ForegroundColor Yellow
}
Write-Host "==================================================" -ForegroundColor Cyan

if (-not $WhatIf) {
    $confirm = Read-Host "`nDo you want to proceed with the deployment? (yes/no)"
    if ($confirm -ne 'yes') {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Deploy each component
foreach ($component in $deploymentOrder) {
    $componentPath = Join-Path $PlatformPath $component.Name
    
    if (-not (Test-Path $componentPath)) {
        Write-Host "`n⚠ Skipping $($component.Name) (path not found)" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n==================================================" -ForegroundColor Cyan
    Write-Host "🚀 Deploying: $($component.Name)" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    
    Push-Location $componentPath
    
    try {
        Write-Host "Initializing..." -ForegroundColor Green
        terragrunt init
        
        if ($WhatIf) {
            Write-Host "Planning changes..." -ForegroundColor Green
            terragrunt plan
        } else {
            Write-Host "Applying changes..." -ForegroundColor Green
            terragrunt apply -auto-approve
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ $($component.Name) deployed successfully" -ForegroundColor Green
            } else {
                Write-Error "Failed to deploy $($component.Name)"
                Pop-Location
                exit 1
            }
        }
    }
    catch {
        Write-Error "Error deploying $($component.Name): $_"
        Pop-Location
        exit 1
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "✅ Platform Deployment Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Host "`nThis was a preview run. No changes were applied." -ForegroundColor Yellow
} else {
    Write-Host "`nPlatform resources are now ready." -ForegroundColor Green
    Write-Host "Next: Deploy workload environments using deploy-workload.ps1" -ForegroundColor Yellow
}
