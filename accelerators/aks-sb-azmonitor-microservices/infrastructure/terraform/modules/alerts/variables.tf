variable "location" {
  type        = string
  description = "Location for the Azure Workbook"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Azure Workbook"
}

variable "action_group_name" {
  type        = string
  description = "Name for the default action group"
}

variable "notification_email_address" {
  type        = string
  description = "Email address for alert notifications"
}

variable "cosmosdb_id" {
  type        = string
  description = "Id for monitored Cosmos DB"
}

variable "servicebus_namespace_id" {
  type        = string
  description = "Id for monitored Service Bus namespace"
}

variable "aks_id" {
  type        = string
  description = "Id for monitored AKS cluster"
}

variable "kv_id" {
  type        = string
  description = "Id for monitored Key Vault"
}

variable "app_insights_id" {
  type        = string
  description = "Id for monitored Application Insights"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Id for monitored Log Analytics workspace"
}
