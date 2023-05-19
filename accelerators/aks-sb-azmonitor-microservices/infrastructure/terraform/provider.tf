provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.31.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.10"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.0.0"
    }
  }
}
