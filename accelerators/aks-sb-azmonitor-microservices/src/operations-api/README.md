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

## Docker Container

* Rename `.env.sample` to `.env` and add connection strings for Service Bus and Application Insights.
* Run `docker compose up` to run the service.