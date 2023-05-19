# Running the service

## Pre-Requisites

1. Service Bus [namespace](https://docs.microsoft.com/cli/azure/servicebus/namespace?view=azure-cli-latest#az-servicebus-namespace-create) with [topic](https://docs.microsoft.com/cli/azure/servicebus/topic?view=azure-cli-latest#az-servicebus-topic-create) and [subscription](https://docs.microsoft.com/cli/azure/servicebus/topic/subscription?view=azure-cli-latest#az-servicebus-topic-subscription-create)
1. Application Insights [account](https://docs.microsoft.com/azure/azure-monitor/app/create-new-resource#azure-cli-preview)
1. Cosmos DB [account](https://docs.microsoft.com/cli/azure/cosmosdb?view=azure-cli-latest#az-cosmosdb-create) with [database](https://docs.microsoft.com/cli/azure/cosmosdb/sql/database?view=azure-cli-latest#az-cosmosdb-sql-database-create) and [container](https://docs.microsoft.com/cli/azure/cosmosdb/sql/container?view=azure-cli-latest)

## Debugging from VSCode Dev Container

* Open the project in the dev container.
  * Make sure to open in the devcontainer
* Rename `.env.sample` to `.env` and add connection strings for Service Bus, Cosmos DB and Application Insights.
* Configure debugger to use the "Python: Service" configuration.
* Run the Debugger.
* Post a message to the the Service Bus Topic similar to the [sample message](#sample-message).

## Docker Container

* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Run `docker compose up` to run the service.
* Post a message to the the Service Bus Topic similar to the [sample message](#sample-message).

## Sample Message

``` json
{
    "id": "08e222e4-5180-4f35-a8d6-e41b47b6447c",
    "timestamp": "2022-06-24T17:10:28.000+00:00",
    "product": {
        "name": "toys",
        "quantity": 100
    },
    "port": {
        "source": "New York City",
        "destination": "Tacoma"
    },
    "demandDates": {
        "start": "2022-06-24T00:00:00.000+00:00",
        "end": "2022-06-30T00:00:00.000+00:00"
    },
    "valid": false,
    "errorMessage": "Bad stuff happened when it was validated"
}
```
