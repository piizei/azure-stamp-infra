output "aks_id" {
  value = module.compute.aks_id
}

output "acr_login_server" {
  value = azurerm_container_registry.shared.login_server
}
