#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validate Azure Landing Zone configuration

.DESCRIPTION
    Validates Terraform and Terragrunt configurations across all environments

.PARAMETER Environment
    The environment to validate (optional, validates all if not specified)

.EXAMPLE
    .\validate.ps1

.EXAMPLE
    .\validate.ps1 -Environment prod
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('prod', 'dev', 'test')]
    [string]$Environment
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$EnvironmentsPath = Join-Path $ScriptRoot "environments"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Azure Landing Zone Validation" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$totalChecks = 0
$passedChecks = 0
$failedChecks = 0

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Green

# Terraform
try {
    terraform version | Out-Null
    Write-Host "✓ Terraform installed" -ForegroundColor Green
    $passedChecks++
} catch {
    Write-Host "✗ Terraform not found" -ForegroundColor Red
    $failedChecks++
}
$totalChecks++

# Terragrunt
try {
    terragrunt --version | Out-Null
    Write-Host "✓ Terragrunt installed" -ForegroundColor Green
    $passedChecks++
} catch {
    Write-Host "✗ Terragrunt not found" -ForegroundColor Red
    $failedChecks++
}
$totalChecks++

# Azure CLI
try {
    az version | Out-Null
    Write-Host "✓ Azure CLI installed" -ForegroundColor Green
    $passedChecks++
} catch {
    Write-Host "✗ Azure CLI not found" -ForegroundColor Red
    $failedChecks++
}
$totalChecks++

# Validate configurations
Write-Host "`nValidating Terragrunt configurations..." -ForegroundColor Green

if ($Environment) {
    $envPaths = Get-ChildItem -Path $EnvironmentsPath -Directory | Where-Object { $_.Name -eq $Environment }
} else {
    $envPaths = Get-ChildItem -Path $EnvironmentsPath -Directory
}

foreach ($env in $envPaths) {
    $regions = Get-ChildItem -Path $env.FullName -Directory
    
    foreach ($region in $regions) {
        $components = Get-ChildItem -Path $region.FullName -Directory -Recurse -Depth 0
        
        foreach ($component in $components) {
            $totalChecks++
            $componentName = "$($env.Name)/$($region.Name)/$($component.Name)"
            
            Push-Location $component.FullName
            
            try {
                Write-Host "  Validating $componentName..." -ForegroundColor Yellow
                
                # Validate terragrunt configuration
                terragrunt validate-inputs 2>&1 | Out-Null
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ $componentName" -ForegroundColor Green
                    $passedChecks++
                } else {
                    Write-Host "  ✗ $componentName - validation failed" -ForegroundColor Red
                    $failedChecks++
                }
            }
            catch {
                Write-Host "  ✗ $componentName - error: $_" -ForegroundColor Red
                $failedChecks++
            }
            finally {
                Pop-Location
            }
        }
    }
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Total Checks: $totalChecks" -ForegroundColor White
Write-Host "Passed: $passedChecks" -ForegroundColor Green
Write-Host "Failed: $failedChecks" -ForegroundColor $(if ($failedChecks -gt 0) { "Red" } else { "Green" })
Write-Host "==================================================" -ForegroundColor Cyan

if ($failedChecks -gt 0) {
    Write-Host "`nValidation completed with errors." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll validations passed!" -ForegroundColor Green
    exit 0
}
