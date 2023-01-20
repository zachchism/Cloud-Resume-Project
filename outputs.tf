output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "function_app_name" {
  value       = azurerm_linux_function_app.fa.name
  description = "Deployed function app name"
}

output "function_app_default_hostname" {
  value       = azurerm_linux_function_app.fa.default_hostname
  description = "Deployed function app hostname"
}

output "cosmosdb_connectionstrings" {
  value = azurerm_cosmosdb_account.db.endpoint
}

output "KS" {
  value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=${azurerm_key_vault_secret.ks.name})"
}