targetScope = 'subscription'

//parameters section
@description('Specifies the supported Azure location (region) where the resources will be deployed')
@minLength(1)
param location string

@description('This value will explain who is the author of specific resources and will be reflected in every deployed tool')
@minLength(1)
param uniqueUserName string

@description('Name for the Cosmos DB SQL database')
@minLength(1)
param cosmosDatabaseName string

@description('Name for the first Cosmos DB SQL container')
@minLength(1)
param cosmosContainer1Name string

@description('Name for the second Cosmos DB SQL container')
@minLength(1)
param cosmosContainer2Name string

@description('Name for the third Cosmos DB SQL container')
@minLength(1)
param cosmosContainer3Name string

@description('Name for the first Service Bus Queue')
@minLength(1)
param serviceBusQueue1Name string

@description('Name for the second Service Bus Queue')
@minLength(1)
param serviceBusQueue2Name string

@description('Name for the Service Bus Topic')
@minLength(1)
param serviceBusTopicName string

@description('Name for the first Service Bus Subscription')
@minLength(1)
param serviceBusSubscription1Name string

@description('Name for the second Service Bus Subscription')
@minLength(1)
param serviceBusSubscription2Name string

@description('Name for the first Service Bus Subscriptions filter rule')
@minLength(1)
param serviceBusTopicRule1Name string

@description('Name for the second Service Bus Subscriptions filter rule')
@minLength(1)
param serviceBusTopicRule2Name string

@description('Tenant Id for the service principal that will be in charge of KeyVault access')
@minLength(1)
param kvTenantId string = tenant().tenantId

@description('Definition Id for AcrPull role')
@minLength(1)
// 7f951dda-4ed3-4680-a7ca-43fe172d538d is the ID for AcrPull
// see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
param roleAcrPull string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

@description('Configure Azure Active Directory authentication for Kubernetes cluster')
param aksAadAuth bool = false

@description('The object ID of the Azure Active Directory user to make cluster admin (only valid if aksAadAuth is true)')
param aksAadAdminUserObjectId string = ''

@description('Email address for alert notifications')
@minLength(1)
param notificationEmailAddress string

//load abbreviations for Azure features
var abbrs = loadJsonContent('abbreviations.json')

//variables section
var toolName = 'bicep'
var resourceGroupName = '${abbrs.resourcesResourceGroups}${toolName}-${uniqueUserName}'
var acrName = '${abbrs.containerRegistryRegistries}${toolName}${uniqueUserName}'
var kvName = '${abbrs.keyVaultVaults}${toolName}-${uniqueUserName}'
var appInsightsName = '${abbrs.insightsComponents}${uniqueUserName}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${toolName}-${uniqueUserName}'
var aksName = '${abbrs.containerServiceManagedClusters}${toolName}-${uniqueUserName}'
var cosmosDBName = '${abbrs.documentDBDatabaseAccounts}${toolName}-${uniqueUserName}'
var serviceBusName = '${abbrs.serviceBusNamespaces}${toolName}-${uniqueUserName}'

//resourceGroup section
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: roleAcrPull
}

//modules section
module acr 'modules/acr.bicep' = {
  name: 'acrDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    acrName: acrName
    aksPrincipalId: aks.outputs.clusterPrincipalID
    roleDefinitionId: acrPullRoleDefinition.id
  }
}

module kv 'modules/key-vault.bicep' = {
  name: 'keyVaultDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    kvName: kvName
    kvTenantId: kvTenantId
    serviceBusNamespaceName: serviceBus.outputs.serviceBusNamespaceName
    appInsightsConnectionString: appInsights.outputs.connectionString
    logAnalyticsWorkspaceId: appInsights.outputs.workspaceId
    clusterKeyVaultSecretProviderObjectId: aks.outputs.clusterKeyVaultSecretProviderObjectId
    cosmosDBEndpoint: cosmos.outputs.cosmosDBEndpoint
    cosmosDBAccountName: cosmos.outputs.cosmosDBAccountName
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsightsDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    appInsightsName: appInsightsName
    logAnalyticsName: logAnalyticsName
  }
}

module workbook 'modules/workbooks.bicep' = {
  name: 'workbookDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    workspaceId: appInsights.outputs.workspaceId
    uniqueUserName: uniqueUserName
    serviceBusNamespaceId: serviceBus.outputs.serviceBusNamespaceId
    appInsightsId: appInsights.outputs.appInsightsId
    keyVaultId: kv.outputs.kvId
    aksId: aks.outputs.clusterId
  }
}

module aks 'modules/aks.bicep' = {
  name: 'kubernetesDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    aksName: aksName
    logAnalyticsWorkspaceId: appInsights.outputs.workspaceId
    aksAadAuth: aksAadAuth
    aksAadAdminUserObjectId: aksAadAdminUserObjectId
  }
}

module cosmos 'modules/cosmos.bicep' = {
  name: 'cosmosDBDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    accountName: cosmosDBName
    databaseName: cosmosDatabaseName
    container1Name: cosmosContainer1Name
    container2Name: cosmosContainer2Name
    container3Name: cosmosContainer3Name
    logAnalyticsWorkspaceId: appInsights.outputs.workspaceId
  }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'serviceBusDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    serviceBusName: serviceBusName
    serviceBusQueue1Name: serviceBusQueue1Name
    serviceBusQueue2Name: serviceBusQueue2Name
    serviceBusTopicName: serviceBusTopicName
    serviceBusSubscription1Name: serviceBusSubscription1Name
    serviceBusSubscription2Name: serviceBusSubscription2Name
    serviceBusTopicRule1Name: serviceBusTopicRule1Name
    serviceBusTopicRule2Name: serviceBusTopicRule2Name
    logAnalyticsWorkspaceId: appInsights.outputs.workspaceId
  }
}

module alerts 'modules/alerts.bicep' = {
  name: 'alertsDeploy'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    actionGroupName: 'default-actiongroup'
    notificationEmailAddress: notificationEmailAddress
    cosmosDBId: cosmos.outputs.cosmosDBId
    keyVaultId: kv.outputs.kvId
    serviceBusNamespaceId: serviceBus.outputs.serviceBusNamespaceId
    aksClusterId: aks.outputs.clusterId
    appInsightsId: appInsights.outputs.appInsightsId
    logAnalyticsWorkspaceId: appInsights.outputs.workspaceId
  }
}

//output section
output rg_name string = resourceGroup.name
output insights_name string = appInsights.outputs.insightsName
output sb_namespace_name string = serviceBus.outputs.serviceBusNamespaceName
output cosmosdb_name string = cosmos.outputs.cosmosDBAccountName
output kv_name string = kv.outputs.kvName
output acr_name string = acr.outputs.acrName
output aks_name string = aks.outputs.clusterName
output aks_key_vault_secret_provider_client_id string = aks.outputs.clusterKeyVaultSecretProviderClientId
output tenant_id string = subscription().tenantId
