variable "name" {
  type        = string
  description = "The AKS resource name"
}

variable "location" {
  type        = string
  description = "The Azure region in which AKS should be provisioned"
}

variable "resource_group_name" {
  type        = string
  description = "The Azure Resource Group where the AKS should be provisioned"
}

variable "prefix" {
  type        = string
  description = "Name prefix"
}

variable "kubernetes_dns_prefix" {
  type        = string
  description = "AKS DNS prefix"
  default     = "aks"
}

variable "kubernetes_node_count" {
  type        = number
  description = "The agent count"
  default     = 3
}

variable "kubernetes_vm_size" {
  type        = string
  description = "Azure Kubernetes Cluster VM Size"
  default     = "Standard_D2s_v3"
}

variable "kubernetes_vm_disk_size" {
  type        = string
  description = "Azure Kubernetes Cluster VM Disk Size"
  default     = "30"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "The ID of the Log Analytics Workspace related to the cluster."
}

variable "acr_id" {
  type        = string
  description = "Id from ACR to get acrPull role assignment"
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
