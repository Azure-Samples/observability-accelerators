output "name" {
  value = azurerm_cosmosdb_account.account.name
}

output "cosmosdb_id" {
  value = azurerm_cosmosdb_account.account.id
}

output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.account.endpoint
}

output "cosmosdb_key" {
  value     = azurerm_cosmosdb_account.account.primary_key
  sensitive = true
}

