location                       = "eastus"
prefix                         = "dev"
unique_username                = "myusername"
cosmosdb_database_name         = "cargo"
cosmosdb_container1_name       = "valid-cargo"
cosmosdb_container2_name       = "invalid-cargo"
cosmosdb_container3_name       = "operations"
service_bus_queue1_name        = "ingest-cargo"
service_bus_queue2_name        = "operation-state"
service_bus_topic_name         = "validated-cargo"
service_bus_subscription1_name = "valid-cargo"
service_bus_subscription2_name = "invalid-cargo"
service_bus_topic_rule1_name   = "valid"
service_bus_topic_rule2_name   = "invalid"
notification_email_address     = "alias@microsoft.com"