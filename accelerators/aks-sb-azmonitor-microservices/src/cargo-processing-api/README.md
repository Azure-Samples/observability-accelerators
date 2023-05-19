# Running the service

## Pre-Requisites

1. Service Bus [namespace](https://docs.microsoft.com/en-us/cli/azure/servicebus/namespace?view=azure-cli-latest#az-servicebus-namespace-create) with [queue](https://docs.microsoft.com/en-us/cli/azure/servicebus/queue?view=azure-cli-latest#az-servicebus-queue-create)
1. Application Insights [account](https://docs.microsoft.com/en-us/azure/azure-monitor/app/create-new-resource#azure-cli-preview)

## Debugging from VSCode Dev Container

* Open the project in the dev container.
  * Make sure to open in the devcontainer
  * Ignore the alerts for Java on the initial load. The alerts move faster than the dev container builds.
  * If you see an alert for Lombok asking to reload, please do reload.
* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Build the Build task 2 options:
  * From the command pallet `Tasks: Run Build Task`
  * From the terminal `mvn -B verify`
* Configure debugger to use the "Launch Application" configuration.
* Run the Debugger.
* Post a message to ".../cargo/{GUID VALUE}" that conforms to the [Cargo API](../../api-spec/main.cadl) specification.

## Docker Container

* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Run `docker compose up` to run the service.
* Post a message to ".../cargo/{GUID VALUE}" that conforms to the [Cargo API](../../api-spec/main.cadl) specification.

## Samples

Sample PUT request:

``` bash
curl --request PUT \
  --url http://localhost:8080/cargo/2dfc711b-7335-4b17-aede-2d67fbf6866f \
  --header 'Content-Type: application/json' \
  --data '{
    "product": {
    "name": "Toys",
    "quantity": 100
  },
  "port": {
    "source": "New York City",
    "destination": "Seattle"
  },
  "demandDates": {
    "start": "2022-06-24T00:00:00.000Z",
    "end": "2022-06-30T00:00:00.000Z"
  }
}'
```

Sample POST request:

``` bash
curl --request POST \
  --url http://localhost:8080/cargo/ \
  --header 'Content-Type: application/json' \
  --data '{
  "product": {
    "name": "Toys",
    "quantity": 100
  },
  "port": {
    "source": "New York City",
    "destination": "Tacoma"
  },
  "demandDates": {
    "start": "2022-06-24T00:00:00.000Z",
    "end": "2022-06-30T00:00:00.000Z"
  }
}'
```
