include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../terraform/modules/resource-group"
}

inputs = {
  resource_groups = {
    connectivity = {
      resource_group_name = "rg-platform-connectivity-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      lock_notes          = "Platform connectivity resources - contact platform team before changes"
      additional_tags = {
        Tier      = "Platform"
        Component = "Connectivity"
        Owner     = "PlatformTeam"
      }
    }
    management = {
      resource_group_name = "rg-platform-management-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      lock_notes          = "Platform management resources - contact platform team before changes"
      additional_tags = {
        Tier      = "Platform"
        Component = "Management"
        Owner     = "PlatformTeam"
      }
    }
    security = {
      resource_group_name = "rg-platform-security-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      lock_notes          = "Platform security resources - contact platform team before changes"
      additional_tags = {
        Tier      = "Platform"
        Component = "Security"
        Owner     = "PlatformTeam"
      }
    }
    dns = {
      resource_group_name = "rg-platform-dns-eastus"
      location            = "eastus"
      lock_level          = "CanNotDelete"
      lock_notes          = "Platform DNS resources - contact platform team before changes"
      additional_tags = {
        Tier      = "Platform"
        Component = "DNS"
        Owner     = "PlatformTeam"
      }
    }
  }
  
  tags = {
    Tier        = "Platform"
    ManagedBy   = "Terragrunt"
    Repository  = "Azure_landing_zone"
  }
}
