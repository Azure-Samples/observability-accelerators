# Running the service

## Pre-Requisites

1. Service Bus [namespace](https://docs.microsoft.com/cli/azure/servicebus/namespace?view=azure-cli-latest#az-servicebus-namespace-create) with [queue](https://docs.microsoft.com/cli/azure/servicebus/queue?view=azure-cli-latest#az-servicebus-queue-create) and [topic](https://docs.microsoft.com/cli/azure/servicebus/topic?view=azure-cli-latest#az-servicebus-topic-create)
1. Application Insights [account](https://docs.microsoft.com/azure/azure-monitor/app/create-new-resource#azure-cli-preview)

## Running from VSCode Dev Container

* Open the project in the dev container.
* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Transpile typescript - `npm run build`. If you want to have transpilation happen automatically when you save code changes, run `npm run watch-build` in a separate terminal window.
* Run javascript - `npm run start`. If you want to have the application restart on code changes, run `npm run watch` instead.
* Post a message to the the Service Bus Queue similar to the [sample message](#sample-message)

## Docker Container

* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Run `docker compose up` to run the service.
* Post a message to the the Service Bus Queue similar to the [sample message](#sample-message)

## Sample Message

When posting a message to the service bus, also ensure a traceparent custom property has been set to a value that conforms pattern defined [by w3c](https://www.w3.org/TR/trace-context/#trace-context-http-headers-format).

For example a value like: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01

```json
{
  "operationId": "56bb0b4c-5c8c-4361-9771-25f997cf651b",
  "data": {
    "timestamp": "2022-07-29T00:00:00.000Z",
    "id": "f725da7e-af18-4bf2-85f9-610504cc3d40",
    "product": {
      "name": "minerals",
      "quantity": 2
    },
    "port": {
      "source": "Boston",
      "destination": "Charlotte"
    },
    "demandDates": {
      "start": "2022-07-28T00:00:00.000Z",
      "end": "2022-07-29T00:00:00.000Z"
    }
  }
}
```
