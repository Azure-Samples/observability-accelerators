@description('Default value obtained from resource group, it can be overwritten')
param location string = resourceGroup().location

@description('Name of the Application Insights instance')
param appInsightsName string

@description('Name of the Log Analytics instance')
param logAnalyticsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

output connectionString string = applicationInsights.properties.ConnectionString
output workspaceId string = logAnalyticsWorkspace.id
output insightsName string = applicationInsights.name
output appInsightsId string = applicationInsights.id
