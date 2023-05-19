variable "app_insights_name" {
  type        = string
  description = "The name of the Application Insights resource"
}

variable "location" {
  type        = string
  description = "The Azure region in which AppInsights should be provisioned"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where the AppInsights should be provisioned"
}

variable "application_type" {
  type        = string
  description = "The kind of application that will be sending the telemetry"
  default     = "web"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "The resource name for log analytics"
}

variable "log_analytics_workspace_sku" {
  type        = string
  description = "Specifies the SKU of the Log Analytics Workspace."
  default     = "PerGB2018"
}
