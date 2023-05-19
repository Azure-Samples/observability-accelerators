variable "kev_vault_name" {
  type        = string
  description = "Name of the Key Vault instance"
}

variable "location" {
  type        = string
  description = "The Azure region in which Key Vault should be provisioned"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where the Key Vault should be provisioned"
}

variable "key_vault_secrets" {
  type        = map(string)
  description = "Map name/value of secrets for the AKV."
}

variable "secrets_expiration_date" {
  type        = string
  description = "Secrets expiration date."
  default     = "2022-12-30T20:00:00Z"
}

variable "key_vault_diagnostic_settings_name" {
  type        = string
  description = "Name for the diagnostic settings"
  default     = "keyVaultDiagnostics"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Id for the targeted log analytics workspace"
}

variable "aks_key_vault_secret_provider_object_id" {
  type        = string
  description = "The Object ID of the user-defined Managed Identity used by the AKS Secret Provider"
}
