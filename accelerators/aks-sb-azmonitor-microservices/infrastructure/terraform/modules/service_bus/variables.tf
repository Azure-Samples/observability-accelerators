variable "services_bus_namespace_name" {
  type        = string
  description = "Name for the service bus namespace"
}

variable "location" {
  type        = string
  description = "Location for the service bus namespace"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the service bus namespace"
}

variable "service_bus_capacity" {
  type        = number
  description = "Capacity for the Service Bus namespace"
  default     = 0
}

variable "service_bus_sku" {
  type        = string
  description = "Sku for the service bus namespace"
  default     = "Standard"
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
  description = "Name for the service bus topic"
}

variable "service_bus_valid_subscription" {
  type        = string
  description = "Name for the valid subscription"
}

variable "service_bus_invalid_subscription" {
  type        = string
  description = "Name for the valid subscription"
}

variable "service_bus_valid_rule" {
  type        = string
  description = "Name for the valid rule"
}

variable "service_bus_invalid_rule" {
  type        = string
  description = "Name for the invalid rule"
}

variable "service_bus_diagnostic_settings_name" {
  type        = string
  description = "Name for the diagnostic settings"
  default     = "serviceBusDiagnostics"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Id for the targeted log analytics workspace"
}
