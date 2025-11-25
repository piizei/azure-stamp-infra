module "stamp" {
  source          = "../../modules/stamp"
  stamp_id        = var.stamp_id
  subscription_id = var.subscription_id
}

locals {
  shared_enabled = try(module.stamp.shared.enabled, true)
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

data "terraform_remote_state" "shared" {
  count   = local.shared_enabled ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = module.stamp.backend.resource_group_name
    storage_account_name = module.stamp.backend.storage_account_name
    container_name       = module.stamp.backend.container_name
    use_azuread_auth     = true
    key                  = module.stamp.backend.shared_key
  }
}

locals {
  shared_storage_account_id = local.shared_enabled && length(data.terraform_remote_state.shared) > 0 ? lookup(data.terraform_remote_state.shared[0].outputs, "storage_account_id", null) : null
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "compute" {
  name     = module.stamp.naming.compute_rg
  location = module.stamp.location
  tags     = module.stamp.tags
}

resource "azurerm_container_registry" "shared" {
  name                          = module.stamp.naming.container_registry
  resource_group_name           = azurerm_resource_group.compute.name
  location                      = azurerm_resource_group.compute.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  tags                          = module.stamp.tags
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr" {
  name                = module.stamp.naming.private_endpoint_acr
  location            = module.stamp.location
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.networking.outputs.pe_subnet_id

  private_service_connection {
    name                           = "psc-${module.stamp.naming.container_registry}"
    private_connection_resource_id = azurerm_container_registry.shared.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }

  tags = module.stamp.tags
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = module.stamp.naming.private_dns_zone_acr
  resource_group_name = azurerm_resource_group.compute.name
  tags                = module.stamp.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "acr-vnet-link"
  resource_group_name   = azurerm_resource_group.compute.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = data.terraform_remote_state.networking.outputs.vnet_id
  registration_enabled  = false
  tags                  = module.stamp.tags
}

module "compute" {
  source = "../../modules/compute"

  resource_group_name    = azurerm_resource_group.compute.name
  location               = azurerm_resource_group.compute.location
  aks_subnet_id          = data.terraform_remote_state.networking.outputs.aks_subnet_id
  tenant_id              = data.azurerm_client_config.current.tenant_id
  service_cidr           = module.stamp.aks.service_cidr
  dns_service_ip         = module.stamp.aks.dns_service_ip
  aks_name               = module.stamp.naming.aks_cluster_name
  dns_prefix             = module.stamp.naming.dns_prefix
  identity_name          = module.stamp.naming.user_assigned_identity
  key_vault_name_prefix  = module.stamp.naming.key_vault_prefix
  aks_vm_size            = module.stamp.aks.vm_size
  aks_node_count         = module.stamp.aks.node_count
  aks_max_pods           = module.stamp.aks.max_pods
  tags                   = module.stamp.tags
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = module.compute.aks_identity_principal_id
}

resource "azurerm_role_assignment" "aks_storage" {
  count               = local.shared_storage_account_id != null ? 1 : 0
  scope                = local.shared_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.compute.aks_identity_principal_id
}
