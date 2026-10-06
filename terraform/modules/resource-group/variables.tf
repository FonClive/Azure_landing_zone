variable "resource_groups" {
  description = "Map of resource groups to create"
  type = map(object({
    resource_group_name = string
    location            = string
    lock_level          = optional(string, "None")
    lock_notes          = optional(string, "Managed by Terraform")
    additional_tags     = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Common tags to apply to all resource groups"
  type        = map(string)
  default     = {}
}
