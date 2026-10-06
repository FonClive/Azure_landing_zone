variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "log_analytics_sku" {
  description = "SKU for Log Analytics"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "Retention period in days"
  type        = number
  default     = 30
}

variable "log_analytics_solutions" {
  description = "List of Log Analytics solutions to enable"
  type        = list(string)
  default = [
    "Security",
    "Updates",
    "ChangeTracking",
    "VMInsights",
    "AzureActivity"
  ]
}

variable "automation_account_name" {
  description = "Name of the Automation Account"
  type        = string
}

variable "diagnostics_storage_name" {
  description = "Name of the diagnostics storage account"
  type        = string
}

variable "action_group_name" {
  description = "Name of the action group"
  type        = string
}

variable "action_group_short_name" {
  description = "Short name for the action group (max 12 chars)"
  type        = string
}

variable "email_receivers" {
  description = "Email receivers for alerts"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
