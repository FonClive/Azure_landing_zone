# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.retention_in_days
  
  tags = var.tags
}

# Log Analytics Solutions
resource "azurerm_log_analytics_solution" "solutions" {
  for_each              = toset(var.log_analytics_solutions)
  solution_name         = each.value
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name
  
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.value}"
  }
  
  tags = var.tags
}

# Automation Account
resource "azurerm_automation_account" "main" {
  name                = var.automation_account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"
  
  tags = var.tags
}

# Link Automation Account to Log Analytics
resource "azurerm_log_analytics_linked_service" "automation" {
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  read_access_id      = azurerm_automation_account.main.id
}

# Storage Account for Diagnostics
resource "azurerm_storage_account" "diagnostics" {
  name                     = var.diagnostics_storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  
  blob_properties {
    delete_retention_policy {
      days = 30
    }
  }
  
  tags = var.tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  
  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }
  
  tags = var.tags
}
