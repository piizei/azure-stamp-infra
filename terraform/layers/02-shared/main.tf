module "stamp" {
  source                    = "../../modules/stamp"
  stamp_id                  = var.stamp_id
  subscription_id           = var.subscription_id
  bootstrap_subscription_id = var.bootstrap_subscription_id
}

data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = module.stamp.backend.resource_group_name
    storage_account_name = module.stamp.backend.storage_account_name
    container_name       = module.stamp.backend.container_name
    use_azuread_auth     = true
    key                  = module.stamp.backend.networking_key
  }
}

resource "azurerm_resource_group" "shared" {
  name     = module.stamp.naming.shared_rg
  location = module.stamp.location
  tags     = module.stamp.tags
}

resource "azurerm_storage_account" "shared" {
  name                      = module.stamp.naming.shared_storage_account
  resource_group_name       = azurerm_resource_group.shared.name
  location                  = azurerm_resource_group.shared.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  shared_access_key_enabled = false
  tags                      = module.stamp.tags
}

resource "azurerm_servicebus_namespace" "shared" {
  name                = module.stamp.naming.service_bus_namespace
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  sku                 = "Premium"
  capacity            = module.stamp.service_bus.capacity
  premium_messaging_partitions = module.stamp.service_bus.partitions
  tags                = module.stamp.tags
}

# Private DNS Zones for Private Endpoints
resource "azurerm_private_dns_zone" "blob" {
  name                = module.stamp.naming.private_dns_zone_blob
  resource_group_name = azurerm_resource_group.shared.name
  tags                = module.stamp.tags
}

resource "azurerm_private_dns_zone" "servicebus" {
  name                = module.stamp.naming.private_dns_zone_sb
  resource_group_name = azurerm_resource_group.shared.name
  tags                = module.stamp.tags
}

# Link DNS Zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-vnet-link"
  resource_group_name   = azurerm_resource_group.shared.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = data.terraform_remote_state.networking.outputs.vnet_id
  registration_enabled  = false
  tags                  = module.stamp.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "servicebus" {
  name                  = "servicebus-vnet-link"
  resource_group_name   = azurerm_resource_group.shared.name
  private_dns_zone_name = azurerm_private_dns_zone.servicebus.name
  virtual_network_id    = data.terraform_remote_state.networking.outputs.vnet_id
  registration_enabled  = false
  tags                  = module.stamp.tags
}

resource "azurerm_private_endpoint" "storage" {
  name                = module.stamp.naming.private_endpoint_storage
  location            = module.stamp.location
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.networking.outputs.pe_subnet_id

  private_service_connection {
    name                           = "psc-${module.stamp.naming.shared_storage_account}"
    private_connection_resource_id = azurerm_storage_account.shared.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = module.stamp.tags
}

resource "azurerm_private_endpoint" "sb" {
  name                = module.stamp.naming.private_endpoint_sb
  location            = module.stamp.location
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.networking.outputs.pe_subnet_id

  private_service_connection {
    name                           = "psc-${module.stamp.naming.service_bus_namespace}"
    private_connection_resource_id = azurerm_servicebus_namespace.shared.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "servicebus-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus.id]
  }

  tags = module.stamp.tags
}
