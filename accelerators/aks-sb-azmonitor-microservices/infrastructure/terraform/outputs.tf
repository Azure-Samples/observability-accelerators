output "rg_name" {
  value = azurerm_resource_group.rg.name
}

output "insights_name" {
  value = module.app_insights.name
}

output "sb_namespace_name" {
  value = module.service_bus.name
}

output "cosmosdb_name" {
  value = module.cosmosdb.name
}

output "kv_name" {
  value = module.key_vault.kv_name
}

output "acr_name" {
  value = module.acr.acr_name
}

output "aks_name" {
  value = module.aks.aks_name
}

output "aks_key_vault_secret_provider_client_id" {
  value     = module.aks.aks_key_vault_secret_provider_client_id
  sensitive = true
}

output "tenant_id" {
  value = data.azurerm_client_config.current_config.tenant_id
}
