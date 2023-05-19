@description('Default value obtained from resource group, it can be overwritten')
param location string = resourceGroup().location

@description('This value will explain who is the author of specific resources and will be reflected in every deployed tool')
@minLength(1)
param uniqueUserName string

@description('Linked resource for Workook')
@minLength(1)
param workspaceId string

@description('Id for monitored Service Bus Namespace')
@minLength(1)
param serviceBusNamespaceId string

@description('Id for monitored Key Vault resource')
@minLength(1)
param keyVaultId string

@description('Id for App Insights resource')
@minLength(1)
param appInsightsId string

@description('Id for monitored AKS resource')
@minLength(1)
param aksId string

var indexWorkbookName =  guid(subscription().subscriptionId, resourceGroup().name, uniqueUserName, 'index')
var baseIndexWorkbookContent = loadTextContent('../../workbooks/index.json')
var indexInsightsWorkbookContent = replace(baseIndexWorkbookContent, '\${app_insights_id}', appInsightsId)
var indexWorkspaceWorkbookContent =replace(indexInsightsWorkbookContent, '\${logs_workspace_id}', uriComponent(workspaceId))
var indexInfrastructureWorkbookContent = replace(indexWorkspaceWorkbookContent, '\${infrastructure_workbook_id}', uriComponent(infrastructureWorkbook.id))
var indexFinalWorkbookContent = replace(indexInfrastructureWorkbookContent, '\${system_workbook_id}', uriComponent(serviceProcessingWorkbook.id))
resource observabilityWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: indexWorkbookName
  location: location
  kind: 'shared'
  properties: {
    category: 'workbook'
    displayName: 'Index'
    serializedData: string(indexFinalWorkbookContent)
    version: '0.01'
    sourceId: workspaceId
  }
}

var infrastructureWorkbookName =  guid(subscription().subscriptionId, resourceGroup().name, uniqueUserName, 'infrastructure')
var baseInfrastructureWorkbookContent = loadTextContent('../../workbooks/infrastructure.json')
var baseInfrastructureSeviceBusWorkbookContent = replace(baseInfrastructureWorkbookContent, '\${servicebus_namespace_id}', serviceBusNamespaceId)
var baseInfrastructureKeyVaultWorkbookContent = replace(baseInfrastructureSeviceBusWorkbookContent, '\${key_vault_id}', keyVaultId)
var infrastructureUrlWorkbookContent =replace(baseInfrastructureKeyVaultWorkbookContent, '\${app_insights_id_url}', uriComponent(appInsightsId))
var baseInfrastructureAksWorkbookContent = replace(infrastructureUrlWorkbookContent, '\${aks_id}', aksId)
var infrastructureFinalWorkbookContent = replace(baseInfrastructureAksWorkbookContent, '\${app_insights_id}', appInsightsId)
resource infrastructureWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: infrastructureWorkbookName
  location: location
  kind: 'shared'
  properties: {
    category: 'workbook'
    displayName: 'Infrastructure'
    serializedData: string(infrastructureFinalWorkbookContent)
    version: '0.01'
    sourceId: workspaceId
  }
}

var serviceProcessingWorkbookName =  guid(subscription().subscriptionId, resourceGroup().name, uniqueUserName, 'service-processing')
var baseServiceProcessingWorkbookContent = loadTextContent('../../workbooks/system-processing.json')
var serviceProcessingWorkbookContent = replace(baseServiceProcessingWorkbookContent, '\${app_insights_id}', appInsightsId)
resource serviceProcessingWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: serviceProcessingWorkbookName
  location: location
  kind: 'shared'
  properties: {
    category: 'workbook'
    displayName: 'System Processing'
    serializedData: string(serviceProcessingWorkbookContent)
    version: '0.01'
    sourceId: workspaceId
  }
}
