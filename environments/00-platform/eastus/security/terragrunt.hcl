include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../terraform/modules/security/key-vault"
}

dependency "resource_group" {
  config_path = "../resource-groups"
}

dependency "management" {
  config_path = "../management"
}

inputs = {
  key_vault_name                = "kv-platform-eastus"
  location                      = "eastus"
  resource_group_name           = dependency.resource_group.outputs.resource_group_names["security"]
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enabled_for_deployment        = false
  enabled_for_disk_encryption   = true
  enabled_for_template_deployment = true
  
  # Platform Key Vault should be more restrictive
  default_network_acl_action = "Deny"
  allowed_ip_ranges          = []  # Add your admin IPs here
  allowed_subnet_ids         = []  # Add platform subnets here
  
  log_analytics_workspace_id = dependency.management.outputs.log_analytics_workspace_id
  
  tags = {
    Tier      = "Platform"
    Component = "Security"
    Owner     = "PlatformTeam"
    Purpose   = "Platform secrets and certificates"
  }
}
