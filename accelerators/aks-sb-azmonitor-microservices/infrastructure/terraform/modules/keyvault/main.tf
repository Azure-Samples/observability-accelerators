data "azurerm_client_config" "current_config" {}

resource "azurerm_key_vault" "akv" {
  name                = var.kev_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current_config.tenant_id
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "admin" {
  key_vault_id = azurerm_key_vault.akv.id
  tenant_id    = data.azurerm_client_config.current_config.tenant_id
  object_id    = data.azurerm_client_config.current_config.object_id

  key_permissions = [
    "Create",
    "Get",
    "List",
    "Delete"
  ]

  secret_permissions = [
    "List",
    "Set",
    "Get",
    "Delete",
    "Purge",
    "Recover",
    "Backup",
    "Restore"
  ]
}

resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.akv.id
  tenant_id    = data.azurerm_client_config.current_config.tenant_id
  object_id    = var.aks_key_vault_secret_provider_object_id

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_key_vault_secret" "akvSecret" {
  for_each = var.key_vault_secrets

  name            = each.key
  value           = each.value
  key_vault_id    = azurerm_key_vault.akv.id
  content_type    = "text/plain"
  expiration_date = var.secrets_expiration_date

  # explicitly depend on access policy so destroy works
  depends_on = [
    azurerm_key_vault_access_policy.admin
  ]
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  name                       = var.key_vault_diagnostic_settings_name
  target_resource_id         = azurerm_key_vault.akv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  /*
  category groups are still not allowed so we need to set all fields one by one
  reference: https://github.com/hashicorp/terraform-provider-azurerm/issues/17349
  supported log categories per resource can be found here:
  https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs-categories
  */

  log {
    category = "AuditEvent"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  log {
    category = "AzurePolicyEvaluationDetails"
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
