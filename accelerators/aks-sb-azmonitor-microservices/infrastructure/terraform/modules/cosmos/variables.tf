variable "account_name" {
  description = "CosmosDB account name"
}

variable "location" {
  type        = string
  description = "The Azure region in which CosmosDB should be provisioned"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where the CosmosDB should be provisioned"
}

variable "cosmosdb_database_name" {
  type        = string
  description = "Name for the Cosmos DB SQL database"
}

variable "cosmosdb_valid_container_name" {
  description = "Name for the Cosmos DB SQL container that stores valid cargo"
}

variable "cosmosdb_invalid_container_name" {
  description = "Name for the Cosmos DB SQL container that stores invalid cargo"
}

variable "cosmosdb_operations_container_name" {
  description = "Name for the Cosmos DB SQL container that stores operations"
}

variable "cosmos_db_diagnostic_settings_name" {
  type        = string
  description = "Name for the diagnostic settings"
  default     = "cosmosDbDiagnostics"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Id for the targeted log analytics workspace"
}
