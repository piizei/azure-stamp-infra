output "storage_account_id" {
  value = azurerm_storage_account.shared.id
}

output "service_bus_id" {
  value = azurerm_servicebus_namespace.shared.id
}
