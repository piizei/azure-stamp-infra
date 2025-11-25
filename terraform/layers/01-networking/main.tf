module "stamp" {
  source          = "../../modules/stamp"
  stamp_id        = var.stamp_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "networking" {
  name     = module.stamp.naming.networking_rg
  location = module.stamp.location
  tags     = module.stamp.tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  vnet_name           = module.stamp.naming.vnet_name
  address_space       = module.stamp.networking.address_space
  aks_subnet_cidr     = module.stamp.networking.aks_subnet_cidr
  pe_subnet_cidr      = module.stamp.networking.pe_subnet_cidr
  aks_subnet_name     = module.stamp.naming.aks_subnet_name
  pe_subnet_name      = module.stamp.naming.pe_subnet_name
  nsg_name            = module.stamp.naming.nsg_name
  tags                = module.stamp.tags
}
