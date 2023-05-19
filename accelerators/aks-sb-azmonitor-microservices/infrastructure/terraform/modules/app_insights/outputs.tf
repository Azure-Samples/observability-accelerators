output "name" {
  value = azurerm_application_insights.app_insights.name
}

output "connection_string" {
  value     = azurerm_application_insights.app_insights.connection_string
  sensitive = true
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}

output "app_insights_id" {
  value = azurerm_application_insights.app_insights.id
}
