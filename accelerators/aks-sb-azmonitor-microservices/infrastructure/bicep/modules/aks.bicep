@description('Default value obtained from resource group, it can be overwritten')
param location string = resourceGroup().location

@description('The name of the AKS resource')
@minLength(1)
param aksName string

@description('Disk size (in GB) to provision for each of the agent pool nodes. Specifying 0 will apply the default disk size for that agentVMSize')
@minValue(0)
@maxValue(1023)
param aksDiskSizeGB int = 30

@description('The number of nodes for the cluster')
@minValue(1)
@maxValue(50)
param aksNodeCount int = 3

@description('The size of the Virtual Machine')
param aksVMSize string = 'Standard_D2s_v3'

@description('The name of the Log Analytics workspace linked to AKS')
@minLength(1)
param logAnalyticsWorkspaceId string

@description('Configure Azure Active Directory authentication for Kubernetes cluster')
param aksAadAuth bool

@description('The object ID of the Azure Active Directory user to make cluster admin (only valid if aksAadAuth is true)')
param aksAadAdminUserObjectId string = ''

var aksAadProfile = {
  managed: true
  enableAzureRBAC: true
  tenantId: subscription().tenantId
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-09-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks'
    aadProfile: aksAadAuth ? aksAadProfile : null
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: aksDiskSizeGB
        count: aksNodeCount
        minCount: 1
        maxCount: aksNodeCount
        vmSize: aksVMSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
      }
    ]
    addonProfiles: {
      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }
  }
}

resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aksAadAuth) {
  name: guid(subscription().id, resourceGroup().id, 'aks-admin-${aksAadAdminUserObjectId}')
  scope: aks
  properties: {
    // Azure Kubernetes Service Cluster Admin Role
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8')
    principalId: aksAadAdminUserObjectId
  }
}
resource userRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (aksAadAuth) {
  name: guid(subscription().id, resourceGroup().id, 'aks-user-${aksAadAdminUserObjectId}')
  scope: aks
  properties: {
    // Azure Kubernetes Service Cluster User Role
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4abbcc35-e782-43d8-92c5-2d3f1bd2253f')
    principalId: aksAadAdminUserObjectId
  }
}

output clusterName string = aks.name
output clusterId string = aks.id
output clusterPrincipalID string = aks.properties.identityProfile.kubeletidentity.objectId
output clusterKeyVaultSecretProviderClientId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.clientId
output clusterKeyVaultSecretProviderObjectId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
