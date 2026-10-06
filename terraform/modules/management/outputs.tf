output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_key" {
  description = "Log Analytics Workspace Key"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "automation_account_id" {
  description = "Automation Account ID"
  value       = azurerm_automation_account.main.id
}

output "diagnostics_storage_id" {
  description = "Diagnostics Storage Account ID"
  value       = azurerm_storage_account.diagnostics.id
}

output "action_group_id" {
  description = "Action Group ID"
  value       = azurerm_monitor_action_group.main.id
}
