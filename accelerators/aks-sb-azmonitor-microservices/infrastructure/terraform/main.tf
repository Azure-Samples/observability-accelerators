data "azurerm_client_config" "current_config" {}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}-tf-${var.unique_username}"
  location = var.location
}

//Cosmos DB module
resource "azurecaf_name" "cosmosdb" {
  name          = "accl"
  resource_type = "azurerm_cosmosdb_account"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "cosmosdb" {
  source                             = "./modules/cosmos"
  account_name                       = azurecaf_name.cosmosdb.result
  location                           = azurerm_resource_group.rg.location
  resource_group_name                = azurerm_resource_group.rg.name
  cosmosdb_database_name             = var.cosmosdb_database_name
  cosmosdb_valid_container_name      = var.cosmosdb_container1_name
  cosmosdb_invalid_container_name    = var.cosmosdb_container2_name
  cosmosdb_operations_container_name = var.cosmosdb_container3_name
  log_analytics_workspace_id         = module.app_insights.log_analytics_workspace_id
}

//ACR module
resource "azurecaf_name" "acr" {
  name          = "accl"
  resource_type = "azurerm_container_registry"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "acr" {
  source              = "./modules/acr"
  name                = azurecaf_name.acr.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

//AKS module
resource "azurecaf_name" "aks" {
  name          = "accl"
  resource_type = "azurerm_kubernetes_cluster"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "aks" {
  source                       = "./modules/aks"
  name                         = azurecaf_name.aks.result
  prefix                       = var.prefix
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  acr_id                       = module.acr.acr_id
  log_analytics_workspace_id   = module.app_insights.log_analytics_workspace_id
  aks_aad_auth                 = var.aks_aad_auth
  aks_aad_admin_user_object_id = var.aks_aad_admin_user_object_id
}

//Application Insights module
resource "azurecaf_name" "appi" {
  name          = "accl"
  resource_type = "azurerm_application_insights"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

resource "azurecaf_name" "log" {
  name          = "accl"
  resource_type = "azurerm_log_analytics_workspace"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "app_insights" {
  source                       = "./modules/app_insights"
  app_insights_name            = azurecaf_name.appi.result
  log_analytics_workspace_name = azurecaf_name.log.result
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
}

module "workbooks" {
  source                  = "./modules/workbooks"
  workspace_id            = module.app_insights.log_analytics_workspace_id
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  servicebus_namespace_id = module.service_bus.servicebus_namespace_id
  app_insights_id         = module.app_insights.app_insights_id
  key_vault_id            = module.key_vault.kv_id
  aks_id                  = module.aks.aks_id
}

module "alerts" {
  source                     = "./modules/alerts"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  notification_email_address = var.notification_email_address
  action_group_name          = "default-actiongroup"
  cosmosdb_id                = module.cosmosdb.cosmosdb_id
  servicebus_namespace_id    = module.service_bus.servicebus_namespace_id
  aks_id                     = module.aks.aks_id
  kv_id                      = module.key_vault.kv_id
  app_insights_id            = module.app_insights.app_insights_id
  log_analytics_workspace_id = module.app_insights.log_analytics_workspace_id
}

//Service Bus module
resource "azurecaf_name" "service_bus" {
  name          = "accl"
  resource_type = "azurerm_servicebus_namespace"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "service_bus" {
  source                           = "./modules/service_bus"
  services_bus_namespace_name      = azurecaf_name.service_bus.result
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  log_analytics_workspace_id       = module.app_insights.log_analytics_workspace_id
  service_bus_queue1_name          = var.service_bus_queue1_name
  service_bus_queue2_name          = var.service_bus_queue2_name
  service_bus_topic_name           = var.service_bus_topic_name
  service_bus_valid_subscription   = var.service_bus_subscription1_name
  service_bus_invalid_subscription = var.service_bus_subscription2_name
  service_bus_valid_rule           = var.service_bus_topic_rule1_name
  service_bus_invalid_rule         = var.service_bus_topic_rule2_name
}

//Key Vault module
resource "azurecaf_name" "kv_compute" {
  name          = "accl"
  resource_type = "azurerm_key_vault"
  prefixes      = [var.prefix]
  suffixes      = [azurerm_resource_group.rg.location]
  random_length = 3
  clean_input   = true
}

module "key_vault" {
  source                                  = "./modules/keyvault"
  location                                = azurerm_resource_group.rg.location
  resource_group_name                     = azurerm_resource_group.rg.name
  kev_vault_name                          = azurecaf_name.kv_compute.result
  log_analytics_workspace_id              = module.app_insights.log_analytics_workspace_id
  aks_key_vault_secret_provider_object_id = module.aks.aks_key_vault_secret_provider_object_id
  key_vault_secrets = tomap(
    {
      "AppInsightsConnectionString" = module.app_insights.connection_string
      "ServiceBusConnectionString"  = module.service_bus.connection_string
      "CosmosDBEndpoint"            = module.cosmosdb.cosmosdb_endpoint
      "CosmosDBKey"                 = module.cosmosdb.cosmosdb_key
    }
  )
}
