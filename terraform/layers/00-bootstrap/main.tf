module "stamp" {
  source          = "../../modules/stamp"
  stamp_id        = var.stamp_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "tfstate" {
  name     = module.stamp.naming.tfstate_rg
  location = module.stamp.location
  tags     = module.stamp.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = module.stamp.naming.tfstate_storage_account
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"  
  shared_access_key_enabled = false
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = true
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "tfstate_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "tfstate" {
  name                  = module.stamp.backend.container_name
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"

  depends_on = [azurerm_role_assignment.tfstate_contributor]
}
