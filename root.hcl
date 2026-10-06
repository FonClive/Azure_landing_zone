# Root Terragrunt Configuration
# This file contains common configuration for all environments

locals {
  # Parse the file path to extract environment information
  parsed = regex(".*/environments/(?P<environment>[^/]+)/(?P<region>[^/]+)/(?P<component>[^/]+)", get_terragrunt_dir())
  environment = local.parsed.environment
  region      = local.parsed.region
  component   = local.parsed.component
}

# Configure Terragrunt to use OpenTofu instead of Terraform
terraform_binary = "tofu"

# Configure remote state storage in Azure Storage Account
remote_state {
  backend = "azurerm"
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  
  config = {
    resource_group_name  = "rg-terraform-state-${local.environment}"
    storage_account_name = "sttfstate${local.environment}"
    container_name       = "tfstate"
    key                  = "${local.environment}/${local.region}/${local.component}/terraform.tfstate"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}
EOF
}

# Common inputs for all modules
inputs = {
  environment = local.environment
  region      = local.region
  
  tags = {
    Environment = local.environment
    ManagedBy   = "Terragrunt"
    Repository  = "Azure_landing_zone"
    IaC         = "OpenTofu"
  }
}
