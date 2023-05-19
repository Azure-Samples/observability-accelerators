variable "location" {
  type        = string
  description = "Specifies the supported Azure location (region) where the resources will be deployed"
}

variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "unique_username" {
  type        = string
  description = "This value will explain who is the author of specific resources and will be reflected in every deployed tool"
}

variable "cosmosdb_database_name" {
  type        = string
  description = "Name for the Cosmos DB SQL database"
}

variable "cosmosdb_container1_name" {
  type        = string
  description = "Name for the first Cosmos DB SQL container"
}

variable "cosmosdb_container2_name" {
  type        = string
  description = "Name for the second Cosmos DB SQL container"
}

variable "cosmosdb_container3_name" {
  description = "Name for the third Cosmos DB SQL container"
}

variable "service_bus_queue1_name" {
  type        = string
  description = "Name for the first service bus queue (ingest)"
}

variable "service_bus_queue2_name" {
  type        = string
  description = "Name for the second service bus queue (operations)"
}

variable "service_bus_topic_name" {
  type        = string
  description = "Name for the Service Bus Topic"
}

variable "service_bus_subscription1_name" {
  type        = string
  description = "Name for the first Service Bus Subscription"
}

variable "service_bus_subscription2_name" {
  type        = string
  description = "Name for the second Service Bus Subscription"
}

variable "service_bus_topic_rule1_name" {
  type        = string
  description = "Name for the first Service Bus Subscriptions filter rulee"
}

variable "service_bus_topic_rule2_name" {
  type        = string
  description = "Name for the second Service Bus Subscriptions filter rulee"
}

variable "aks_aad_auth" {
  type        = bool
  description = "Configure Azure Active Directory authentication for Kubernetes cluster"
  default     = false
}

variable "aks_aad_admin_user_object_id" {
  type        = string
  description = "Object ID of the AAD user to be added as an admin to the AKS cluster"
  default     = ""
}

variable "notification_email_address" {
  type        = string
  description = "Email address for alert notifications"
}
