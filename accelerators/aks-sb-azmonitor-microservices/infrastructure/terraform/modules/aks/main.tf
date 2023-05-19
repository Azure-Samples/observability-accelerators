data "azurerm_client_config" "current_config" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = var.kubernetes_dns_prefix
  private_cluster_enabled = false


  default_node_pool {
    name                = "agentpool"
    min_count           = 1
    max_count           = var.kubernetes_node_count
    enable_auto_scaling = true
    type                = "VirtualMachineScaleSets"
    vm_size             = var.kubernetes_vm_size
    os_disk_size_gb     = var.kubernetes_vm_disk_size
  }

  // Use dynamic to conditionally set AAD auth block
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aks_aad_auth ? [1] : []
    content {
      managed            = true
      tenant_id          = data.azurerm_client_config.current_config.tenant_id
      azure_rbac_enabled = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_admin_role" {
  count                = var.aks_aad_auth ? 1 : 0
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.aks_aad_admin_user_object_id
}
resource "azurerm_role_assignment" "aks_user_role" {
  count                = var.aks_aad_auth ? 1 : 0
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.aks_aad_admin_user_object_id
}
