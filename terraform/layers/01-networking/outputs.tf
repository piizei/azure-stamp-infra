output "stamp_id" {
  value = module.stamp.stamp_id
}

output "resource_group_name" {
  value = azurerm_resource_group.networking.name
}

output "location" {
  value = azurerm_resource_group.networking.location
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "aks_subnet_id" {
  value = module.networking.aks_subnet_id
}

output "pe_subnet_id" {
  value = module.networking.pe_subnet_id
}
