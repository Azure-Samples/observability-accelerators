output "name" {
  value = azurerm_servicebus_namespace.bus_namespace.name
}

output "connection_string" {
  value     = azurerm_servicebus_namespace.bus_namespace.default_primary_connection_string
  sensitive = true
}

output "servicebus_namespace_id" {
  value = azurerm_servicebus_namespace.bus_namespace.id
}