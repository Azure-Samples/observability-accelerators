@description('Name for the Service Bus Namespace')
@minLength(1)
param serviceBusName string

@description('Default value obtained from resource group, it can be overwritten')
@minLength(1)
param location string = resourceGroup().location

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

@description('Name for diagnostic settings')
@minLength(1)
param diagnosticSettingsName string = 'serviceBusDiagnostics'

@description('Log analytics workspace id')
@minLength(1)
param logAnalyticsWorkspaceId string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    capacity: 1
    name: 'Standard'
    tier: 'Standard'
  }

  properties: {
    publicNetworkAccess: 'Enabled'
  }

  resource serviceBusQueue 'queues' = {
    name: serviceBusQueue1Name
  }

  resource serviceBusQueue2 'queues' = {
    name: serviceBusQueue2Name
  }
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  name: serviceBusTopicName
  parent: serviceBusNamespace
  properties: {
    supportOrdering: true
  }

  resource serviceBusSubscription1 'subscriptions' = {
    name: serviceBusSubscription1Name
    properties: {
      maxDeliveryCount: 1
    }

    resource serviceBusTopicRule 'rules' = {
      name: serviceBusTopicRule1Name
      properties: {
        filterType: 'SqlFilter'
        sqlFilter: {
          sqlExpression: 'valid = True'
        }
      }
    }
  }

  resource serviceBusSubscription2 'subscriptions' = {
    name: serviceBusSubscription2Name
    properties: {
      maxDeliveryCount: 1
    }

    resource serviceBusTopicRule 'rules' = {
      name: serviceBusTopicRule2Name
      properties: {
        filterType: 'SqlFilter'
        sqlFilter: {
          sqlExpression: 'valid = False'
        }
      }
    }
  }
}

resource serviceBusDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  scope: serviceBusNamespace
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

output serviceBusNamespaceName string = serviceBusNamespace.name
output serviceBusNamespaceId string = serviceBusNamespace.id
