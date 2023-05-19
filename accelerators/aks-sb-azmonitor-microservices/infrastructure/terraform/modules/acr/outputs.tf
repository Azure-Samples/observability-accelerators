output "acr_id" {
  value     = azurerm_container_registry.acr.id
  sensitive = true
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}
