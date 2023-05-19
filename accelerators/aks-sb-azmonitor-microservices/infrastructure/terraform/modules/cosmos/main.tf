resource "azurerm_cosmosdb_account" "account" {
  name                      = var.account_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = true


  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 400
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_cosmosdb_account.account.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name
}

resource "azurerm_cosmosdb_sql_container" "valid_container" {
  name                = var.cosmosdb_valid_container_name
  resource_group_name = azurerm_cosmosdb_account.account.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
}

resource "azurerm_cosmosdb_sql_container" "invalid_container" {
  name                = var.cosmosdb_invalid_container_name
  resource_group_name = azurerm_cosmosdb_account.account.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
}

resource "azurerm_cosmosdb_sql_container" "operations_container" {
  name                = var.cosmosdb_operations_container_name
  resource_group_name = azurerm_cosmosdb_account.account.resource_group_name
  account_name        = azurerm_cosmosdb_account.account.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
}



resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  name                           = var.cosmos_db_diagnostic_settings_name
  target_resource_id             = azurerm_cosmosdb_account.account.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"

  /*
  category groups are still not allowed so we need to set all fields one by one
  reference: https://github.com/hashicorp/terraform-provider-azurerm/issues/17349
  supported log categories per resource can be found here:
  https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
  */

  log {
    category = "DataPlaneRequests"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "QueryRuntimeStatistics"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "PartitionKeyStatistics"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "PartitionKeyRUConsumption"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "ControlPlaneRequests"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "CassandraRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "GremlinRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "MongoRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "TableApiRequests"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "Requests"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
