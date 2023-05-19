# Alerts

[Alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview) proactively notify application administrators when the data ingested by Azure Monitor suggests the application is experiencing problems, or will in the near future. Visualization tooling like Workbooks highlight important indicators from the application and can illuminate issues, but require active, manual watching by administrators. Alerts can take those same indicators one step further by taking automated, prescriptive action when certain conditions are met. Rather than requiring active watching of a dashboard, alerts let application admins understand and resolve issues with the application _before_ they become problematic for most downstream users of the system.

Azure alert rules are scoped to a specific resource. These resources emit different telemetry signals, defined by the resource type. Service Bus namespaces emit a numeric `DeadletteredMessages` metric, for instance, while AKS emits `node_cpu_usage_percentage`, among other metrics. The application relies on a number of metric alerts that utilize these signals. It also utilizes several log alerts that use KQL queries to pull the data evaluated in alert conditions. The `cargoProcessingAPIHealthCheckFailure` alert, for example, uses the following KQL query to pull failed health checks for the `cargo-processing-api` service:

```sql
requests
| where cloud_RoleName == "cargo-processing-api" and name == "GET /actuator/health" and success == "False"
```

Alert conditions combine the signal and some numeric threshold that may be met over a defined window of time. If a signal exceeds some threshold over a time window defined in an alert rule, the alert fires and triggers an action group. Severity levels dictate the relative importance of the alert and mitigation steps. Certain alerts suggest with high likelihood that the application is already experiencing issues, like the microservice exceptions alert (`microserviceExceptions`). Immediate attention should be paid to uncover the underlying issue and resolve the alert. Others, like the Key Vault saturation rate (`keyVaultSaturation`) or number of invalid cargo objects saved (`cosmosInvalidCargo`), don't necessarily require immediate action but suggest that an administrator should take a closer look.

We elected to create alert rules for signals that suggested issues with the underlying infrastructure or the service code deployed to AKS that utilizes it. Each of the microservices has average duration, health check failure, and health check not reporting alerts. A single microservice exceptions alert is split across the 5 services and alerts when any microservice throws a certain number of exceptions. The combination of these alerts proactively notifies when a service has experienced failure or become less performant. Service Bus exposes many message count metrics, like dead-lettered and abandoned messages, that are also important indicators of application issues and are used in rules. Deadlettered messages, for example, may suggest that the initial `cargo-processing-api` service is not properly validating the cargo object structure before sending the message to the `ingest-cargo` queue. The AKS and Log Analytics alerts include the pre-defined, [recommended alert rules](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview#recommended-alert-rules) that suggest impending failure for those resource types. The full list of alerts deployed alongside the application is as follows:

| Alert Name                                 | Description                                                                                        | Entity            | Alert Type | Severity |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------- | ----------------- | ---------- | -------- |
| cosmosRUs                                  | Alert when RUs exceed 400.                                                                         | Cosmos DB         | Metric     | 1        |
| cosmosInvalidCargo                         | Alert when more than 10 documents have been saved to the invalid-cargo container.                  | Cosmos DB         | Metric     | 3        |
| serviceBusAbandonedMessages                | Alert when a Service Bus entity has abandoned more than 10 messages.                               | Service Bus       | Metric     | 2        |
| serviceBusDeadLetteredMessages             | Alert when a Service Bus entity has dead-lettered more than 10 messages.                           | Service Bus       | Metric     | 2        |
| serviceBusThrottledRequests                | Alert when a Service Bus entity has throttled more than 10 requests.                               | Service Bus       | Metric     | 2        |
| aksCPUPercentage                           | Alert when Node CPU percentage exceeds 80.                                                         | AKS               | Metric     | 2        |
| aksMemoryPercentage                        | Alert when Node memory working set percentage exceeds 80.                                          | AKS               | Metric     | 2        |
| aksPodRestarts                             | Alert when a microservice restarts more than once.                                                 | AKS               | Log        | 1        |
| keyVaultSaturation                         | Alert when Key Vault saturation falls outside the range of a dynamic threshold.                    | Key Vault         | Metric     | 3        |
| logAnalyticsDataIngestionDailyCap          | Alert when the Log Analytics data ingestion daily cap has been reached.                            | Log Analytics     | Log        | 2        |
| logAnalyticsDataIngestionRate              | Alert when the Log Analytics max data ingestion rate has been reached.                             | Log Analytics     | Log        | 2        |
| logAnalyticsOperationalIssues              | Alert when the Log Analytics workspace has an operational issue.                                   | Log Analytics     | Log        | 3        |
| microserviceExceptions                     | Alert when a microservice throws more than 5 exceptions.                                           | App Insights/Code | Log        | 1        |
| productQtyScheduledForDestinationPort      | Alert when a single port/destination receives more than quantity 1000 of a given product.          | App Insights/Code | Metric     | 3        |
| e2eAverageDuration                         | Alert when the end to end average request duration exceeds 5 seconds.                              | App Insights/Code | Log        | 1        |
| cargoProcessingAPIRequests                 | Alert when the cargo-processing-api microservice is not receiving any requests.                    | App Insights/Code | Log        | 3        |
| cargoProcessingAPIAverageDuration          | Alert when the cargo-processing-api microservice average request duration exceeds 2 seconds.       | App Insights/Code | Log        | 1        |
| cargoProcessingAPIHealthCheckFailure       | Alert when a cargo-processing-api microservice health check fails.                                 | App Insights/Code | Log        | 1        |
| cargoProcessingAPIHealthCheckNotReporting  | Alert when the cargo-processing-api microservice health check is not reporting.                    | App Insights/Code | Log        | 1        |
| cargoProcessingValidatorAverageDuration    | Alert when the cargo-processing-validator microservice average request duration exceeds 2 seconds. | App Insights/Code | Log        | 1        |
| validCargoManagerAverageDuration           | Alert when the valid-cargo-manager microservice average request duration exceeds 2 seconds.        | App Insights/Code | Log        | 1        |
| validCargoManagerHealthCheckFailure        | Alert when a valid-cargo-manager microservice health check fails.                                  | App Insights/Code | Log        | 1        |
| validCargoManagerHealthCheckNotReporting   | Alert when the valid-cargo-manager microservice health check is not reporting.                     | App Insights/Code | Log        | 1        |
| invalidCargoManagerAverageDuration         | Alert when the invalid-cargo-manager microservice average request duration exceeds 2 seconds.      | App Insights/Code | Log        | 1        |
| invalidCargoManagerHealthCheckFailure      | Alert when an invalid-cargo-manager microservice health check fails.                               | App Insights/Code | Log        | 1        |
| invalidCargoManagerHealthCheckNotReporting | Alert when the invalid-cargo-manager microservice health check is not reporting.                   | App Insights/Code | Log        | 1        |
| operationsAPIAverageDuration               | Alert when the operations-api microservice average request duration exceeds 1 second.              | App Insights/Code | Log        | 1        |
| operationsAPIHealthCheckFailure            | Alert when an operations-api microservice health check fails.                                      | App Insights/Code | Log        | 1        |
| operationsAPIHealthCheckNotReporting       | Alert when the operations-api microservice health check is not reporting.                          | App Insights/Code | Log        | 1        |

All alerts in the cargo processing application are [_stateful_](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview#alerts-and-state), meaning that they will fire when the condition is met, but _will not_ fire again until the condition is resolved. They all utilize the same action group, which notifies an administrator via email. [Action groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) _can_ contain additional actions, like triggering webhooks, Logic Apps, Azure Functions, and more. The notification email address is set in the initial `.env`:

```yaml
# Email address for alert notifications
EMAIL_ADDRESS=youremail@organization.com
```

Most alerts use static thresholds to evaluate the telemetry signals emitted from the application. These alert rules use specific threshold values for a signal pre-defined by the application team. The Cosmos DB RUs alert, for instance, defines a static threshold of 400 RUs that will trigger an alert when exceeded. The Key Vault saturation rate alert, however, uses a [dynamic threshold](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-dynamic-thresholds) that uses a machine learning algorithm to define it. The algorithm uses 10 days of recent data to evaluate patterns and calculate the correct threshold for the signal. The thresholds and windows defined in the alert conditions are easily configurable via [Bicep](../infrastructure/bicep/modules/alerts.bicep) or [Terraform](../infrastructure/terraform/modules/alerts/main.tf).

No [alert processing rules](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-processing-rules?tabs=portal) are used, but could be easily added to modify or suppress certain alerts before they fire.
