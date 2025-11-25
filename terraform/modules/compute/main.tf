resource "azurerm_user_assigned_identity" "aks" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  tags                = var.tags

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    vnet_subnet_id = var.aks_subnet_id
    zones          = [1, 2, 3]
    max_pods       = var.aks_max_pods

    # Java workload optimizations
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr    = var.service_cidr
    dns_service_ip  = var.dns_service_ip
  }

  # Enable OIDC for workload identity (useful for Java apps connecting to Azure services)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
}

resource "azurerm_key_vault" "this" {
  name                        = "${var.key_vault_name_prefix}-${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"
  tags     = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_role_assignment" "aks_kv" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
