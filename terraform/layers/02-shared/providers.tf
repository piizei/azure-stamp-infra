terraform {
  backend "azurerm" {
    key = "shared.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id   = var.subscription_id
  storage_use_azuread = true
}
