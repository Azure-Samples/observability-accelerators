resource "azurerm_monitor_action_group" "default" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = length(var.action_group_name) <= 12 ? var.action_group_name : substr(var.action_group_name, 0, 12)

  email_receiver {
    name                    = "email-receiver"
    email_address           = var.notification_email_address
    use_common_alert_schema = false
  }
}

resource "azurerm_monitor_metric_alert" "cosmos_rus" {
  name                = "cosmos_rus"
  resource_group_name = var.resource_group_name
  scopes              = [var.cosmosdb_id]
  severity            = 1
  description         = "Alert when RUs exceed 400."
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 400
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "cosmos_invalid_cargo" {
  name                = "cosmos_invalid_cargo"
  resource_group_name = var.resource_group_name
  scopes              = [var.cosmosdb_id]
  severity            = 3
  description         = "Alert when more than 10 documents have been saved to the invalid-cargo container."
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "DocumentCount"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
    dimension {
      name     = "CollectionName"
      operator = "Include"
      values   = ["invalid_cargo"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "service_bus_abandoned_messages" {
  name                = "service_bus_abandoned_messages"
  resource_group_name = var.resource_group_name
  scopes              = [var.servicebus_namespace_id]
  severity            = 2
  description         = "Alert when a Service Bus entity has abandoned more than 10 messages."
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "AbandonMessage"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "service_bus_dead_lettered_messages" {
  name                = "service_bus_dead_lettered_messages"
  resource_group_name = var.resource_group_name
  scopes              = [var.servicebus_namespace_id]
  severity            = 2
  description         = "Alert when a Service Bus entity has dead-lettered more than 10 messages."
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "DeadletteredMessages"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 10
    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "service_bus_throttled_requests" {
  name                = "service_bus_throttled_requests"
  resource_group_name = var.resource_group_name
  scopes              = [var.servicebus_namespace_id]
  severity            = 2
  description         = "Alert when a Service Bus entity has throttled more than 10 requests."
  enabled             = false
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "ThrottledRequests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "aks_cpu_percentage" {
  name                = "aks_cpu_percentage"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_id]
  severity            = 2
  description         = "Alert when Node CPU percentage exceeds 80."
  enabled             = false
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "aks_memory_percentage" {
  name                = "aks_memory_percentage"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_id]
  severity            = 2
  description         = "Alert when Node memory working set percentage exceeds 80."
  enabled             = false
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

resource "azurerm_monitor_metric_alert" "key_vault_saturation_rate" {
  name                = "key_vault_saturation_rate"
  resource_group_name = var.resource_group_name
  scopes              = [var.kv_id]
  severity            = 3
  description         = "Alert when Key Vault saturation falls outside the range of a dynamic threshold."
  enabled             = false
  frequency           = "PT5M"
  window_size         = "PT5M"

  dynamic_criteria {
    metric_namespace         = "Microsoft.KeyVault/vaults"
    metric_name              = "SaturationShoebox"
    aggregation              = "Average"
    operator                 = "GreaterOrLessThan"
    alert_sensitivity        = "Medium"
    evaluation_total_count   = 4
    evaluation_failure_count = 4
  }

  action {
    action_group_id = azurerm_monitor_action_group.default.id
  }
}

# Tenant specific issues prevent deployment of custom metric alert
# 
# resource "azurerm_monitor_metric_alert" "product_qty_scheduled_for_destination_port" {
#   name                = "product_qty_scheduled_for_destination_port"
#   resource_group_name = var.resource_group_name
#   scopes              = [var.app_insights_id]
#   severity            = 3
#   description         = "Alert when a single port/destination receives more than quantity 1000 of a given product."
#   enabled             = false
#   frequency           = "PT1M"
#   window_size         = "PT1M"

#   criteria {
#     metric_namespace       = "azure.applicationinsights"
#     metric_name            = "port_product_qty"
#     aggregation            = "Total"
#     operator               = "GreaterThan"
#     threshold              = 1000
#     skip_metric_validation = true

#     dimension {
#       name     = "destination"
#       operator = "Include"
#       values   = ["*"]
#     }

#     dimension {
#       name     = "product"
#       operator = "Include"
#       values   = ["*"]
#     }
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.default.id
#   }
# }

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "microservice_exceptions" {
  name                = "microservice_exceptions"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when a microservice throws more than 5 exceptions."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      exceptions
      QUERY
    time_aggregation_method = "Count"
    threshold               = 5
    operator                = "GreaterThan"

    dimension {
      name     = "cloud_RoleName"
      operator = "Include"
      values   = ["*"]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cargo_processing_api_requests" {
  name                = "cargo_processing_api_requests"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 3
  description             = "Alert when the cargo-processing-api microservice is not receiving any requests."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")
      QUERY
    time_aggregation_method = "Count"
    # usage of the "Equal" operator is currently blocked 
    # LessThan 1 should suffice as a workaround for Equal 0 until the bug is fixed is released in 3.36.0
    # please see discussion at https://github.com/hashicorp/terraform-provider-azurerm/issues/19581
    threshold = 1
    operator  = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "e2e_average_duration" {
  name                = "e2e_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the end to end average request duration exceeds 5 seconds."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      let cargo_processing_api = requests
      | where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")
      | project-rename ingest_timestamp = timestamp
      | project ingest_timestamp, operation_Id;
      let operation_api_succeeded = requests
      | where cloud_RoleName  == "operations-api" and name == "ServiceBus.process" and customDimensions["operation-state"]  == "Succeeded"
      | extend operation_api_completed = timestamp + (duration*1ms)
      | project operation_Id, operation_api_completed;
      cargo_processing_api
      | join kind=inner operation_api_succeeded  on $left.operation_Id == $right.operation_Id
      | extend end_to_end_Duration_ms = (operation_api_completed - ingest_timestamp) /1ms
      | summarize avg(end_to_end_Duration_ms)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 5000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_end_to_end_Duration_ms"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cargo_processing_api_average_duration" {
  name                = "cargo_processing_api_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the cargo-processing-api microservice average request duration exceeds 2 seconds."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")
        | summarize avg(duration)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 2000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_duration"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cargo_processing_validator_average_duration" {
  name                = "cargo_processing_validator_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the cargo-processing-validator microservice average request duration exceeds 2 seconds."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "cargo-processing-validator" and (name == "ServiceBus.ProcessMessage" or name == "ServiceBusQueue.ProcessMessage")
        | summarize avg(duration)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 2000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_duration"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "valid_cargo_manager_average_duration" {
  name                = "valid_cargo_manager_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the valid-cargo-manager microservice average request duration exceeds 2 seconds."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "valid-cargo-manager" and name == "ServiceBusTopic.ProcessMessage"
        | summarize avg(duration)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 2000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_duration"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "invalid_cargo_manager_average_duration" {
  name                = "invalid_cargo_manager_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the invalid-cargo-manager microservice average request duration exceeds 2 seconds."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "invalid-cargo-manager" and name == "ServiceBusTopic.ProcessMessage"
        | summarize avg(duration)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 2000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_duration"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "operations_api_average_duration" {
  name                = "operations_api_average_duration"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the operations-api microservice average request duration exceeds 1 second."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "operations-api" and name == "ServiceBus.process"
        | summarize avg(duration)
      QUERY
    time_aggregation_method = "Average"
    threshold               = 1000
    operator                = "GreaterThan"
    metric_measure_column   = "avg_duration"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_data_ingestion_daily_cap" {
  name                = "log_analytics_data_ingestion_daily_cap"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.log_analytics_workspace_id]
  severity                = 2
  description             = "Alert when the Log Analytics data ingestion daily cap has been reached."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      _LogOperation
        | where Category == "Ingestion"
        | where Operation has "Data collection"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    resource_id_column      = "_ResourceId"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_data_ingestion_rate" {
  name                = "log_analytics_data_ingestion_rate"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.log_analytics_workspace_id]
  severity                = 2
  description             = "Alert when the Log Analytics max data ingestion rate has been reached."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      _LogOperation
        | where Category == "Ingestion"
        | where Operation has "Ingestion rate"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    resource_id_column      = "_ResourceId"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_operational_issues" {
  name                = "log_analytics_operational_issues"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency = "P1D"
  window_duration      = "P1D"
  scopes               = [var.log_analytics_workspace_id]
  severity             = 3
  description          = "Alert when the Log Analytics workspace has an operational issue."
  enabled              = false
  # tf stateful rules can not run in a frequency greater than 12 hours, auto_mitigation_enabled must be false
  auto_mitigation_enabled = false

  criteria {
    query                   = <<-QUERY
      _LogOperation
        | where Level == "Warning"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    resource_id_column      = "_ResourceId"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cargo_processing_api_health_check_failure" {
  name                = "cargo_processing_api_health_check_failure"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when a cargo-processing-api microservice health check fails."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "cargo-processing-api" and name == "GET /actuator/health" and success == "False"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cargo_processing_api_health_check_not_reporting" {
  name                = "cargo_processing_api_health_check_not_reporting"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the cargo-processing-api microservice health check is not reporting."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "cargo-processing-api" and name == "GET /actuator/health"
      QUERY
    time_aggregation_method = "Count"
    # usage of the "Equal" operator is currently blocked 
    # LessThan 1 should suffice as a workaround for Equal 0 until the bug is fixed is released in 3.36.0
    # please see discussion at https://github.com/hashicorp/terraform-provider-azurerm/issues/19581
    threshold = 1
    operator  = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "valid_cargo_manager_health_check_failure" {
  name                = "valid_cargo_manager_health_check_failure"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT30M"
  window_duration         = "PT30M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when a valid-cargo-manager microservice health check fails."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      customMetrics
        | where cloud_RoleName == "valid-cargo-manager" and name == "HeartbeatState" and value != 2
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "valid_cargo_manager_health_check_not_reporting" {
  name                = "valid_cargo_manager_health_check_not_reporting"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT30M"
  window_duration         = "PT30M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the valid-cargo-manager microservice health check is not reporting."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      customMetrics
        | where cloud_RoleName == "valid-cargo-manager" and name == "HeartbeatState"
      QUERY
    time_aggregation_method = "Count"
    # usage of the "Equal" operator is currently blocked 
    # LessThan 1 should suffice as a workaround for Equal 0 until the bug is fixed is released in 3.36.0
    # please see discussion at https://github.com/hashicorp/terraform-provider-azurerm/issues/19581
    threshold = 1
    operator  = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "invalid_cargo_manager_health_check_failure" {
  name                = "invalid_cargo_manager_health_check_failure"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when an invalid-cargo-manager microservice health check fails."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      traces
        | where cloud_RoleName == "invalid-cargo-manager" and message contains "peeked at messages for over"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "invalid_cargo_manager_health_check_not_reporting" {
  name                = "invalid_cargo_manager_health_check_not_reporting"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the invalid-cargo-manager microservice health check is not reporting."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      traces
        | where cloud_RoleName == "invalid-cargo-manager" and (message contains "since last peek" or message contains "peeked at messages for over")
      QUERY
    time_aggregation_method = "Count"
    # usage of the "Equal" operator is currently blocked 
    # LessThan 1 should suffice as a workaround for Equal 0 until the bug is fixed is released in 3.36.0 is released in 3.36.0
    # please see discussion at https://github.com/hashicorp/terraform-provider-azurerm/issues/19581
    threshold = 1
    operator  = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "operations_api_health_check_failure" {
  name                = "operations_api_health_check_failure"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when an operations-api microservice health check fails."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "operations-api" and name == "GET /actuator/health" and success == "False"
      QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "operations_api_health_check_not_reporting" {
  name                = "operations_api_health_check_not_reporting"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.app_insights_id]
  severity                = 1
  description             = "Alert when the operations-api microservice health check is not reporting."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      requests
        | where cloud_RoleName == "operations-api" and name == "GET /actuator/health"
      QUERY
    time_aggregation_method = "Count"
    # usage of the "Equal" operator is currently blocked 
    # LessThan 1 should suffice as a workaround for Equal 0 until the bug is fixed is released in 3.36.0
    # please see discussion at https://github.com/hashicorp/terraform-provider-azurerm/issues/19581
    threshold = 1
    operator  = "LessThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "aks_pod_restarts" {
  name                = "aks_pod_restarts"
  resource_group_name = var.resource_group_name
  location            = var.location

  evaluation_frequency    = "PT5M"
  window_duration         = "PT5M"
  scopes                  = [var.log_analytics_workspace_id]
  severity                = 1
  description             = "Alert when a microservice restarts more than once."
  enabled                 = false
  auto_mitigation_enabled = true

  criteria {
    query                   = <<-QUERY
      KubePodInventory
        | summarize numRestarts = sum(PodRestartCount) by ServiceName
      QUERY
    time_aggregation_method = "Total"
    threshold               = 1
    operator                = "GreaterThan"
    metric_measure_column   = "numRestarts"

    dimension {
      name     = "ServiceName"
      operator = "Include"
      values = [
        "cargo-processing-api",
        "cargo-processing-validator",
        "invalid-cargo-manager",
        "operations-api",
        "valid-cargo-manager"
      ]
    }

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.default.id]
  }
}
