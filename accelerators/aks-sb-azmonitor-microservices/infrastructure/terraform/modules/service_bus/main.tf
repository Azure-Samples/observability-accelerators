resource "azurerm_servicebus_namespace" "bus_namespace" {
  name                = var.services_bus_namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.service_bus_capacity
  sku                 = var.service_bus_sku
}

resource "azurerm_servicebus_queue" "bus_queue1" {
  name         = var.service_bus_queue1_name
  namespace_id = azurerm_servicebus_namespace.bus_namespace.id
}

resource "azurerm_servicebus_queue" "bus_queue2" {
  name         = var.service_bus_queue2_name
  namespace_id = azurerm_servicebus_namespace.bus_namespace.id
}

resource "azurerm_servicebus_topic" "validation_topic" {
  name         = var.service_bus_topic_name
  namespace_id = azurerm_servicebus_namespace.bus_namespace.id
}

resource "azurerm_servicebus_subscription" "valid_subscription" {
  name               = var.service_bus_valid_subscription
  topic_id           = azurerm_servicebus_topic.validation_topic.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription" "invalid_subscription" {
  name               = var.service_bus_invalid_subscription
  topic_id           = azurerm_servicebus_topic.validation_topic.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription_rule" "valid_rule" {
  name            = var.service_bus_valid_rule
  subscription_id = azurerm_servicebus_subscription.valid_subscription.id
  filter_type     = "SqlFilter"
  sql_filter      = "valid = True"
}

resource "azurerm_servicebus_subscription_rule" "invalid_rule" {
  name            = var.service_bus_invalid_rule
  subscription_id = azurerm_servicebus_subscription.invalid_subscription.id
  filter_type     = "SqlFilter"
  sql_filter      = "valid = False"
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  name                       = var.service_bus_diagnostic_settings_name
  target_resource_id         = azurerm_servicebus_namespace.bus_namespace.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  /*
  category groups are still not allowed so we need to set all fields one by one
  reference: https://github.com/hashicorp/terraform-provider-azurerm/issues/17349
  supported log categories per resource can be found here:
  https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
  */

  log {
    category = "OperationalLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "ApplicationMetricsLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "RuntimeAuditLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "VNetAndIPFilteringLogs"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
