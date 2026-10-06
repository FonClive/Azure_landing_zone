#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Destroy Azure Landing Zone infrastructure

.DESCRIPTION
    This script tears down the Azure Landing Zone infrastructure in the correct order
    to avoid dependency issues.

.PARAMETER Environment
    The environment to destroy (e.g., prod, dev)

.PARAMETER Region
    The Azure region (e.g., eastus, westus2)

.PARAMETER SubscriptionId
    Azure subscription ID

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\destroy.ps1 -Environment prod -Region eastus -SubscriptionId "xxxx-xxxx-xxxx"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('prod', 'dev', 'test')]
    [string]$Environment,

    [Parameter(Mandatory=$true)]
    [ValidateSet('eastus', 'westus2', 'centralus', 'northeurope', 'westeurope')]
    [string]$Region,

    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$EnvironmentPath = Join-Path $ScriptRoot "environments\$Environment\$Region"

Write-Host "==================================================" -ForegroundColor Red
Write-Host "WARNING: Infrastructure Destruction" -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Red
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Subscription: $SubscriptionId" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Red

if (-not $Force) {
    Write-Host "`nThis will PERMANENTLY DELETE all resources in the landing zone." -ForegroundColor Red
    $confirm = Read-Host "Type 'DELETE' to confirm"
    if ($confirm -ne 'DELETE') {
        Write-Host "Destruction cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Set subscription
az account set --subscription $SubscriptionId

# Destruction order (reverse of deployment)
$destructionOrder = @(
    "security",
    "network-spoke-prod",
    "network-spoke-dev",
    "network-hub",
    "management",
    "resource-groups"
)

foreach ($component in $destructionOrder) {
    $componentPath = Join-Path $EnvironmentPath $component
    
    if (-not (Test-Path $componentPath)) {
        Write-Host "`n⚠ Skipping $component (path not found)" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n==================================================" -ForegroundColor Red
    Write-Host "Destroying: $component" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    
    Push-Location $componentPath
    
    try {
        terragrunt destroy -auto-approve
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $component destroyed" -ForegroundColor Green
        } else {
            Write-Warning "Failed to destroy $component completely"
        }
    }
    catch {
        Write-Warning "Error destroying $component: $_"
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "Destruction Complete" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
