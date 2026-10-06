include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../terraform/modules/management"
}

dependency "resource_group" {
  config_path = "../resource-groups"
}

inputs = {
  log_analytics_name      = "law-platform-eastus"
  location                = "eastus"
  resource_group_name     = dependency.resource_group.outputs.resource_group_names["management"]
  log_analytics_sku       = "PerGB2018"
  retention_in_days       = 90
  
  log_analytics_solutions = [
    "Security",
    "Updates",
    "ChangeTracking",
    "VMInsights",
    "AzureActivity",
    "NetworkMonitoring",
    "SecurityCenterFree"
  ]
  
  automation_account_name  = "aa-platform-eastus"
  diagnostics_storage_name = "stplatformdiageastus"
  
  action_group_name       = "ag-platform-alerts"
  action_group_short_name = "platform"
  
  email_receivers = [
    {
      name          = "PlatformTeam"
      email_address = "platform-team@example.com"
    },
    {
      name          = "CloudOps"
      email_address = "cloudops@example.com"
    }
  ]
  
  tags = {
    Tier      = "Platform"
    Component = "Management"
    Owner     = "PlatformTeam"
    Purpose   = "Centralized monitoring and management for all workloads"
  }
}
