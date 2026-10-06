# Create multiple resource groups
resource "azurerm_resource_group" "rg" {
  for_each = var.resource_groups
  
  name     = each.value.resource_group_name
  location = each.value.location
  tags     = merge(var.tags, lookup(each.value, "additional_tags", {}))
}

# Management locks for resource groups
resource "azurerm_management_lock" "rg_lock" {
  for_each = {
    for k, v in var.resource_groups : k => v
    if lookup(v, "lock_level", "None") != "None"
  }
  
  name       = "${each.value.resource_group_name}-lock"
  scope      = azurerm_resource_group.rg[each.key].id
  lock_level = each.value.lock_level
  notes      = lookup(each.value, "lock_notes", "Managed by Terraform")
}
