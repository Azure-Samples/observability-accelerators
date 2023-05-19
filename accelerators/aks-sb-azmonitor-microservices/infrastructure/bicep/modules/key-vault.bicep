@description('Location obtained from resource group')
param location string = resourceGroup().location

@description('KeyVault name')
@minLength(1)
param kvName string

@description('Expected KeyVault sku')
@allowed([
  'premium'
  'standard'
])
param kvSku string = 'standard'

@description('Tenant Id for the service principal that will be in charge of KeyVault access')
@minLength(1)
param kvTenantId string = tenant().tenantId

//secrets stored in KeyVault
@description('Service Bus Namespace name')
@minLength(1)
param serviceBusNamespaceName string

@description('App Insights Connection String')
@minLength(1)
@secure()
param appInsightsConnectionString string

@description('Cosmos DB endpoint')
@minLength(1)
param cosmosDBEndpoint string

@description('Cosmos DB account name')
@minLength(1)
param cosmosDBAccountName string

@description('Name for diagnostic settings')
@minLength(1)
param diagnosticSettingsName string = 'keyVaultDiagnostics'

@description('Log analytics workspace id')
@minLength(1)
param logAnalyticsWorkspaceId string

@description('The Object ID of the user-defined Managed Identity used by the AKS Secret Provider')
@minLength(1)
@secure()
param clusterKeyVaultSecretProviderObjectId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: kvName
  location: location
  properties: {
    tenantId: kvTenantId
    sku: {
      family: 'A'
      name: kvSku
    }
    createMode: 'default'
    publicNetworkAccess: 'Enabled'
    accessPolicies: [
      {
        objectId: clusterKeyVaultSecretProviderObjectId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    enabledForTemplateDeployment: true
  }

  resource appInsightsStringSecret 'secrets' = {
    name: 'AppInsightsConnectionString'
    properties: {
      value: appInsightsConnectionString
    }
  }

  resource serviceBusSecret 'secrets' = {
    name: 'ServiceBusConnectionString'
    properties: {
      value: listKeys(resourceId('Microsoft.ServiceBus/namespaces/AuthorizationRules', serviceBusNamespaceName, 'RootManageSharedAccessKey'), '2022-01-01-preview').primaryConnectionString
    }
  }

  resource cosmosDBEndpointSecret 'secrets' = {
    name: 'CosmosDBEndpoint'
    properties: {
      value: cosmosDBEndpoint
    }
  }

  resource cosmosDBKeySecret 'secrets' = {
    name: 'CosmosDBKey'
    properties: {
      value: listKeys(resourceId('Microsoft.DocumentDB/databaseAccounts', cosmosDBAccountName), '2022-05-15').primaryMasterKey
    }
  }
}

resource keyVaultDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  scope: keyVault
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

output kvName string = keyVault.name
output kvId string = keyVault.id
