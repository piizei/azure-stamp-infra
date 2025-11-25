output "aks_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "aks_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks.principal_id
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}
