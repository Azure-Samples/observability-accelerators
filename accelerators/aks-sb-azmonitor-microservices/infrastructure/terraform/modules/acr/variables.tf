variable "name" {
  type        = string
  description = "resource name"
}

variable "location" {
  type        = string
  description = "The Azure region in which ACR should be provisioned"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where the ACR should be provisioned"
}
