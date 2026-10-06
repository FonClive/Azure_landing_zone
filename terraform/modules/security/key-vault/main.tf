data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  
  network_acls {
    bypass         = "AzureServices"
    default_action = var.default_network_acl_action
    
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
  
  tags = var.tags
}

# Access Policies
resource "azurerm_key_vault_access_policy" "policies" {
  for_each     = var.access_policies
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id
  
  key_permissions         = lookup(each.value, "key_permissions", [])
  secret_permissions      = lookup(each.value, "secret_permissions", [])
  certificate_permissions = lookup(each.value, "certificate_permissions", [])
  storage_permissions     = lookup(each.value, "storage_permissions", [])
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = var.log_analytics_workspace_id != null ? 1 : 0
  name                       = "diag-${var.key_vault_name}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "AuditEvent"
  }
  
  metric {
    category = "AllMetrics"
  }
}
