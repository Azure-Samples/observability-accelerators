variable "workspace_id" {
  type        = string
  description = "Name for the Azure Workbook"
}

variable "location" {
  type        = string
  description = "Location for the Azure Workbook"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Azure Workbook"
}

variable "servicebus_namespace_id" {
  type        = string
  description = "Id for monitored Service Bus Namespace"
}

variable "app_insights_id" {
  type        = string
  description = "Id for Application Insights resource"
}

variable "key_vault_id" {
  type = string
  description = "Id for Key Vault resource"
}

variable "aks_id" {
  type = string
  description = "Id for AKS cluster resource"
}