# Running the service

## Pre-Requisites

1. Service Bus [namespace](https://docs.microsoft.com/cli/azure/servicebus/namespace?view=azure-cli-latest#az-servicebus-namespace-create) with [topic](https://docs.microsoft.com/cli/azure/servicebus/topic?view=azure-cli-latest#az-servicebus-topic-create) and [subscription](https://docs.microsoft.com/cli/azure/servicebus/topic/subscription?view=azure-cli-latest#az-servicebus-topic-subscription-create)
1. Application Insights [account](https://docs.microsoft.com/azure/azure-monitor/app/create-new-resource#azure-cli-preview)
1. Cosmos DB [account](https://docs.microsoft.com/cli/azure/cosmosdb?view=azure-cli-latest#az-cosmosdb-create) with [database](https://docs.microsoft.com/cli/azure/cosmosdb/sql/database?view=azure-cli-latest#az-cosmosdb-sql-database-create) and [container](https://docs.microsoft.com/cli/azure/cosmosdb/sql/container?view=azure-cli-latest)

## Running from VSCode Dev Container

* Open the project in the dev container.
* Rename `appsettings.json.sample` to `appsettings.json` and add connection information for Service Bus, Cosmos DB, and Application Insights.
* Run the application - `dotnet run --project .\valid-cargo-manager.csproj`
* Post a message to the the Service Bus Topic similar to the [sample message](#sample-message)

## Docker Container

* Rename `appsettings.json.sample` to `appsettings.json` and add connection information for Service Bus, Cosmos DB, and Application Insights.
* Run `docker compose up` to run the service.
* Post a message to the the Service Bus Topic similar to the [sample message](#sample-message)

## Sample Message

```json
{
    "operationId": "4be3aab6-0f8f-4d5e-9330-3c0d89950cfa",
    "data": {
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
            "start": "2022-11-24T00:00:00.000+00:00",
            "end": "2022-11-30T00:00:00.000+00:00"
        },
        "valid": true,
        "errorMessage": null
    }
}
```

### Custom Properties

Ensure the following custom properties are also set for the messages posted to the Service Bus topic:

* Diagnostic-Id: When posting a message to the service bus, also ensure a traceparent custom property has been set to a value that conforms pattern defined [by w3c](https://www.w3.org/TR/trace-context/#trace-context-http-headers-format).

    For example a value like: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01

* valid: boolean property identifying whether the cargo object passed validation. For this service to respond to the message the value should be set to True.
