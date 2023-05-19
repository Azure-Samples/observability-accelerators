resource "random_uuid" "index_uuid" {
}
resource "random_uuid" "observability_uuid" {
}
resource "random_uuid" "service_processing_uuid" {
}

resource "azurerm_application_insights_workbook" "index" {
  name                = random_uuid.index_uuid.result
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "Index"
  source_id           = lower(var.workspace_id)
  data_json = templatefile(
    "${path.module}/../../../workbooks/index.json",
    { app_insights_id = var.app_insights_id, logs_workspace_id = urlencode(var.workspace_id), infrastructure_workbook_id = urlencode(azurerm_application_insights_workbook.infrastructure.id), system_workbook_id = urlencode(azurerm_application_insights_workbook.system_processing.id)}
  )
}

resource "azurerm_application_insights_workbook" "infrastructure" {
  name                = random_uuid.observability_uuid.result
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "Infrastructure"
  source_id           = lower(var.workspace_id)
  data_json = templatefile(
    "${path.module}/../../../workbooks/infrastructure.json",
    { servicebus_namespace_id = var.servicebus_namespace_id, key_vault_id = var.key_vault_id, app_insights_id = var.app_insights_id, app_insights_id_url = urlencode(var.app_insights_id), aks_id = var.aks_id }
  )
}

resource "azurerm_application_insights_workbook" "system_processing" {
  name                = random_uuid.service_processing_uuid.result
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "System Processing"
  source_id           = lower(var.workspace_id)
  data_json = templatefile(
    "${path.module}/../../../workbooks/system-processing.json",
    { app_insights_id = var.app_insights_id, app_insights_id_url = urlencode(var.app_insights_id) }
  )
}
