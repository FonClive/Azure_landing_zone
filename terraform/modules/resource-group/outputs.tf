output "resource_group_names" {
  description = "Map of resource group names"
  value       = { for k, v in azurerm_resource_group.rg : k => v.name }
}

output "resource_group_ids" {
  description = "Map of resource group IDs"
  value       = { for k, v in azurerm_resource_group.rg : k => v.id }
}

output "hub_rg_name" {
  description = "Hub resource group name"
  value       = lookup(azurerm_resource_group.rg, "hub", null) != null ? azurerm_resource_group.rg["hub"].name : null
}

output "management_rg_name" {
  description = "Management resource group name"
  value       = lookup(azurerm_resource_group.rg, "management", null) != null ? azurerm_resource_group.rg["management"].name : null
}

output "security_rg_name" {
  description = "Security resource group name"
  value       = lookup(azurerm_resource_group.rg, "security", null) != null ? azurerm_resource_group.rg["security"].name : null
}
