include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../../../terraform/modules/resource-group"
}

inputs = {
  resource_groups = {
    networking = {
      resource_group_name = "rg-dev-networking-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags = {
        Environment = "Development"
        Tier        = "Workload"
        Component   = "Networking"
        Owner       = "DevTeam"
      }
    }
    shared = {
      resource_group_name = "rg-dev-shared-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags = {
        Environment = "Development"
        Tier        = "Workload"
        Component   = "Shared"
        Owner       = "DevTeam"
        Purpose     = "Shared dev resources like ACR, Key Vault"
      }
    }
    app1 = {
      resource_group_name = "rg-dev-app1-eastus"
      location            = "eastus"
      lock_level          = "None"
      additional_tags = {
        Environment = "Development"
        Tier        = "Workload"
        Component   = "Application"
        Owner       = "App1Team"
        Application = "App1"
      }
    }
  }
  
  tags = {
    Environment = "Development"
    Tier        = "Workload"
    ManagedBy   = "Terragrunt"
    Repository  = "Azure_landing_zone"
  }
}
