@description('Default value obtained from resource group, it can be overwritten')
param location string = resourceGroup().location

@description('Name for the default action group')
@minLength(1)
param actionGroupName string

@description('Email address for alert notifications')
@minLength(1)
param notificationEmailAddress string

@description('Cosmos DB resource id')
param cosmosDBId string

@description('Service Bus namespace resource id')
param serviceBusNamespaceId string

@description('AKS cluster resource id')
param aksClusterId string

@description('Key Vault resource id')
param keyVaultId string

@description('Application Insights resource id')
param appInsightsId string

@description('Log Analytics workspace resource id')
param logAnalyticsWorkspaceId string

var defaultMetricAlertActions = [
  {
    actionGroupId: defaultActionGroup.id
  }
]

var defaultLogAlertActions = {
  actionGroups: [
    defaultActionGroup.id
  ]
}

var serviceBusSplitByEntityDimensions = [
  {
    name: 'EntityName'
    operator: 'Include'
    values: [
      '*'
    ]
  }
]

resource defaultActionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    enabled: false
    groupShortName: length(actionGroupName) <= 12 ? actionGroupName : substring(actionGroupName, 0, 12)
    emailReceivers: [
      {
        name: 'email-receiver'
        emailAddress: notificationEmailAddress
        useCommonAlertSchema: false
      }
    ]
  }
}

resource cosmosRusAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'cosmosRUs'
  location: 'global'
  properties: {
    description: 'Alert when RUs exceed 400.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'TotalRequestUnits'
          metricNamespace: 'Microsoft.DocumentDB/databaseAccounts'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 400
        }
      ]
    }
    scopes: [ cosmosDBId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource cosmosInvalidCargoAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'cosmosInvalidCargo'
  location: 'global'
  properties: {
    description: 'Alert when more than 10 documents have been saved to the invalid-cargo container.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'DocumentCount'
          metricNamespace: 'Microsoft.DocumentDB/databaseAccounts'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 10
          dimensions: [
            {
              name: 'CollectionName'
              operator: 'Include'
              values: [
                'invalid-cargo'
              ]
            }
          ]
        }
      ]
    }
    scopes: [ cosmosDBId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 3
    enabled: false
  }
}

resource serviceBusAbandonedMessagesAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'serviceBusAbandonedMessages'
  location: 'global'
  properties: {
    description: 'Alert when a Service Bus entity has abandoned more than 10 messages.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'AbandonMessage'
          metricNamespace: 'Microsoft.ServiceBus/namespaces'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 10
          dimensions: serviceBusSplitByEntityDimensions
        }
      ]
    }
    scopes: [ serviceBusNamespaceId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource serviceBusDeadLetteredMessagesAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'serviceBusDeadLetteredMessages'
  location: 'global'
  properties: {
    description: 'Alert when a Service Bus entity has dead-lettered more than 10 messages.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'DeadletteredMessages'
          metricNamespace: 'Microsoft.ServiceBus/namespaces'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 10
          dimensions: serviceBusSplitByEntityDimensions
        }
      ]
    }
    scopes: [ serviceBusNamespaceId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource serviceBusThrottledRequestsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'serviceBusThrottledRequests'
  location: 'global'
  properties: {
    description: 'Alert when a Service Bus entity has throttled more than 10 requests.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'ThrottledRequests'
          metricNamespace: 'Microsoft.ServiceBus/namespaces'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 10
          dimensions: serviceBusSplitByEntityDimensions
        }
      ]
    }
    scopes: [ serviceBusNamespaceId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource aksCPUPercentageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'aksCPUPercentage'
  location: 'global'
  properties: {
    description: 'Alert when Node CPU percentage exceeds 80.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'node_cpu_usage_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 80
        }
      ]
    }
    scopes: [ aksClusterId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource aksMemoryPercentageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'aksMemoryPercentage'
  location: 'global'
  properties: {
    description: 'Alert when Node memory working set percentage exceeds 80.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'node_memory_working_set_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          operator: 'GreaterThan'
          threshold: 80
        }
      ]
    }
    scopes: [ aksClusterId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource keyVaultSaturationAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'keyVaultSaturation'
  location: 'global'
  properties: {
    description: 'Alert when Key Vault saturation falls outside the range of a dynamic threshold.'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          metricName: 'SaturationShoebox'
          metricNamespace: 'Microsoft.KeyVault/vaults'
          name: 'Metric1'
          skipMetricValidation: false
          timeAggregation: 'Average'
          criterionType: 'DynamicThresholdCriterion'
          operator: 'GreaterOrLessThan'
          alertSensitivity: 'Medium'
          failingPeriods: {
            minFailingPeriodsToAlert: 4
            numberOfEvaluationPeriods: 4
          }
        }
      ]
    }
    scopes: [ keyVaultId ]
    actions: defaultMetricAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 3
    enabled: false
  }
}

// Tenant specific issues prevent deployment of custom metric alert
// 
// resource productQtyScheduledForDestinationPortAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
//   name: 'productQtyScheduledForDestinationPort'
//   location: 'global'
//   properties: {
//     description: 'Alert when a single port/destination receives more than quantity 1000 of a given product.'
//     criteria: {
//       'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
//       allOf: [
//         {
//           metricName: 'port_product_qty'
//           metricNamespace: 'azure.applicationinsights'
//           name: 'Metric1'
//           skipMetricValidation: true
//           timeAggregation: 'Total'
//           criterionType: 'StaticThresholdCriterion'
//           operator: 'GreaterThan'
//           threshold: 1000
//           dimensions: [
//             {
//               name: 'destination'
//               operator: 'Include'
//               values: [
//                 '*'
//               ]
//             }
//             {
//               name: 'product'
//               operator: 'Include'
//               values: [
//                 '*'
//               ]
//             }
//           ]
//         }
//       ]
//     }
//     scopes: [ appInsightsId ]
//     actions: defaultMetricAlertActions
//     evaluationFrequency: 'PT1M'
//     windowSize: 'PT1M'
//     severity: 3
//     enabled: false
//   }
// }

resource microserviceExceptionsAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'microserviceExceptions'
  location: location
  properties: {
    description: 'Alert when a microservice throws more than 5 exceptions.'
    criteria: {
      allOf: [
        {
          query: 'exceptions\n'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 5
          dimensions: [
            {
              name: 'cloud_RoleName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource cargoProcessingAPIRequestsAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'cargoProcessingAPIRequests'
  location: location
  properties: {
    description: 'Alert when the cargo-processing-api microservice is not receiving any requests.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")'
          timeAggregation: 'Count'
          operator: 'Equal'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 3
    enabled: false
  }
}

resource e2eAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'e2eAverageDuration'
  location: location
  properties: {
    description: 'Alert when the end to end average request duration exceeds 5 seconds.'
    criteria: {
      allOf: [
        {
          query: 'let cargo_processing_api = requests\r\n| where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")\r\n| project-rename ingest_timestamp = timestamp\r\n| project ingest_timestamp, operation_Id;\r\nlet operation_api_succeeded = requests\r\n| where cloud_RoleName  == "operations-api" and name == "ServiceBus.process" and customDimensions["operation-state"]  == "Succeeded"\r\n| extend operation_api_completed = timestamp + (duration*1ms)\r\n| project operation_Id, operation_api_completed;\r\ncargo_processing_api\r\n| join kind=inner operation_api_succeeded  on $left.operation_Id == $right.operation_Id\r\n| extend end_to_end_Duration_ms = (operation_api_completed - ingest_timestamp) /1ms\r\n| summarize avg(end_to_end_Duration_ms)'
          metricMeasureColumn: 'avg_end_to_end_Duration_ms'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 5000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource cargoProcessingAPIAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'cargoProcessingAPIAverageDuration'
  location: location
  properties: {
    description: 'Alert when the cargo-processing-api microservice average request duration exceeds 2 seconds.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "cargo-processing-api" and (name == "POST /cargo/" or name == "PUT /cargo/{cargoId}")\r\n| summarize avg(duration)'
          metricMeasureColumn: 'avg_duration'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 2000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource cargoProcessingValidatorAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'cargoProcessingValidatorAverageDuration'
  location: location
  properties: {
    description: 'Alert when the cargo-processing-validator microservice average request duration exceeds 2 seconds.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "cargo-processing-validator" and (name == "ServiceBus.ProcessMessage" or name == "ServiceBusQueue.ProcessMessage")\r\n| summarize avg(duration)'
          metricMeasureColumn: 'avg_duration'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 2000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource validCargoManagerAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'validCargoManagerAverageDuration'
  location: location
  properties: {
    description: 'Alert when the valid-cargo-manager microservice average request duration exceeds 2 seconds.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "valid-cargo-manager" and name == "ServiceBusTopic.ProcessMessage"\r\n| summarize avg(duration)'
          metricMeasureColumn: 'avg_duration'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 2000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource invalidCargoManagerAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'invalidCargoManagerAverageDuration'
  location: location
  properties: {
    description: 'Alert when the invalid-cargo-manager microservice average request duration exceeds 2 seconds.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "invalid-cargo-manager" and name == "ServiceBusTopic.ProcessMessage"\r\n| summarize avg(duration)'
          metricMeasureColumn: 'avg_duration'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 2000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource operationsAPIAverageDurationAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'operationsAPIAverageDuration'
  location: location
  properties: {
    description: 'Alert when the operations-api microservice average request duration exceeds 1 second.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "operations-api" and name == "ServiceBus.process"\r\n| summarize avg(duration)'
          metricMeasureColumn: 'avg_duration'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 1000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource logAnalyticsDataIngestionDailyCapAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'logAnalyticsDataIngestionDailyCap'
  location: location
  properties: {
    description: 'Alert when the Log Analytics data ingestion daily cap has been reached.'
    criteria: {
      allOf: [
        {
          query: '_LogOperation | where Category == "Ingestion" | where Operation has "Data collection"'
          resourceIdColumn: '_ResourceId'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ logAnalyticsWorkspaceId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource logAnalyticsDataIngestionRateAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'logAnalyticsDataIngestionRate'
  location: location
  properties: {
    description: 'Alert when the Log Analytics max data ingestion rate has been reached.'
    criteria: {
      allOf: [
        {
          query: '_LogOperation | where Category == "Ingestion" | where Operation has "Ingestion rate"'
          resourceIdColumn: '_ResourceId'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ logAnalyticsWorkspaceId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 2
    enabled: false
  }
}

resource logAnalyticsOperationalIssuesAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'logAnalyticsOperationalIssues'
  location: location
  properties: {
    description: 'Alert when the Log Analytics workspace has an operational issue.'
    criteria: {
      allOf: [
        {
          query: '_LogOperation | where Level == "Warning"'
          resourceIdColumn: '_ResourceId'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ logAnalyticsWorkspaceId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'P1D'
    windowSize: 'P1D'
    severity: 3
    enabled: false
  }
}

resource cargoProcessingAPIHealthCheckFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'cargoProcessingAPIHealthCheckFailure'
  location: location
  properties: {
    description: 'Alert when a cargo-processing-api microservice health check fails.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "cargo-processing-api" and name == "GET /actuator/health" and success == "False"'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource cargoProcessingAPIHealthCheckNotReportingAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'cargoProcessingAPIHealthCheckNotReporting'
  location: location
  properties: {
    description: 'Alert when the cargo-processing-api microservice health check is not reporting.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "cargo-processing-api" and name == "GET /actuator/health"'
          timeAggregation: 'Count'
          operator: 'Equal'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource validCargoManagerHealthCheckFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'validCargoManagerHealthCheckFailureAlert'
  location: location
  properties: {
    description: 'Alert when a valid-cargo-manager microservice health check fails.'
    criteria: {
      allOf: [
        {
          query: 'customMetrics\r\n| where cloud_RoleName == "valid-cargo-manager" and name == "HeartbeatState" and value != 2'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT30M'
    windowSize: 'PT30M'
    severity: 1
    enabled: false
  }
}

resource validCargoManagerHealthCheckNotReportingAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'validCargoManagerHealthCheckNotReporting'
  location: location
  properties: {
    description: 'Alert when the valid-cargo-manager microservice health check is not reporting.'
    criteria: {
      allOf: [
        {
          query: 'customMetrics\r\n| where cloud_RoleName == "valid-cargo-manager" and name == "HeartbeatState"'
          timeAggregation: 'Count'
          operator: 'Equal'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT30M'
    windowSize: 'PT30M'
    severity: 1
    enabled: false
  }
}

resource invalidCargoManagerHealthCheckFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'invalidCargoManagerHealthCheckFailure'
  location: location
  properties: {
    description: 'Alert when an invalid-cargo-manager microservice health check fails.'
    criteria: {
      allOf: [
        {
          query: 'traces\r\n| where cloud_RoleName == "invalid-cargo-manager" and message contains "peeked at messages for over"'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource invalidCargoManagerHealthCheckNotReportingAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'invalidCargoManagerHealthCheckNotReporting'
  location: location
  properties: {
    description: 'Alert when the invalid-cargo-manager microservice health check is not reporting.'
    criteria: {
      allOf: [
        {
          query: 'traces\r\n| where cloud_RoleName == "invalid-cargo-manager"  and (message contains "since last peek" or message contains "peeked at messages for over")'
          timeAggregation: 'Count'
          operator: 'Equal'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource operationsAPIHealthCheckFailureAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'operationsAPIHealthCheckFailure'
  location: location
  properties: {
    description: 'Alert when an operations-api microservice health check fails.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "operations-api" and name == "GET /actuator/health" and success == "False"'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource operationsAPIHealthCheckNotReportingAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'operationsAPIHealthCheckNotReporting'
  location: location
  properties: {
    description: 'Alert when the operations-api microservice health check is not reporting.'
    criteria: {
      allOf: [
        {
          query: 'requests\r\n| where cloud_RoleName == "operations-api" and name == "GET /actuator/health"'
          timeAggregation: 'Count'
          operator: 'Equal'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    scopes: [ appInsightsId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}

resource aksPodRestartsAlert 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'aksPodRestarts'
  location: location
  properties: {
    description: 'Alert when a microservice restarts more than once.'
    criteria: {
      allOf: [
        {
          query: 'KubePodInventory\r\n| summarize numRestarts = sum(PodRestartCount) by ServiceName'
          metricMeasureColumn: 'numRestarts'
          timeAggregation: 'Total'
          operator: 'GreaterThan'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
          dimensions: [
            {
              name: 'ServiceName'
              operator: 'Include'
              values: [
                'cargo-processing-api'
                'cargo-processing-validator'
                'invalid-cargo-manager'
                'operations-api'
                'valid-cargo-manager'
              ]
            }
          ]
        }
      ]
    }
    scopes: [ logAnalyticsWorkspaceId ]
    actions: defaultLogAlertActions
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    severity: 1
    enabled: false
  }
}
