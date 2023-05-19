#!/bin/bash
set -e

#
# This script expects to find an output.json in the project root with the values
# from the infrastructure deployment.
# It then creates the env files, settings files, and helm chart values files for each service
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RESOURCE_GROUP=$(jq -r '.rg_name' < "$script_dir/../../output.json")
if [[ ${#RESOURCE_GROUP} -eq 0 ]]; then
  echo 'ERROR: Missing output value rg_name' 1>&2
  exit 6
fi

APP_INSIGHTS=$(jq -r '.insights_name' < "$script_dir/../../output.json")
if [[ ${#APP_INSIGHTS} -eq 0 ]]; then
  echo 'ERROR: Missing output value insights_name' 1>&2
  exit 6
fi

SERVICE_BUS_NAMESPACE=$(jq -r '.sb_namespace_name' < "$script_dir/../../output.json")
if [[ ${#SERVICE_BUS_NAMESPACE} -eq 0 ]]; then
  echo 'ERROR: Missing output value sb_namespace_name' 1>&2
  exit 6
fi

COSMOSDB_NAME=$(jq -r '.cosmosdb_name' < "$script_dir/../../output.json")
if [[ ${#COSMOSDB_NAME} -eq 0 ]]; then
  echo 'ERROR: Missing output value cosmosdb_name' 1>&2
  exit 6
fi

ACR_NAME=$(jq -r '.acr_name' < "$script_dir/../../output.json")
if [[ ${#ACR_NAME} -eq 0 ]]; then
  echo 'ERROR: Missing output value acr_name' 1>&2
  exit 6
fi

KEYVAULT_NAME=$(jq -r '.kv_name' < "$script_dir/../../output.json")
if [[ ${#KEYVAULT_NAME} -eq 0 ]]; then
  echo 'ERROR: Missing output value kv_name' 1>&2
  exit 6
fi

TENANT_ID=$(jq -r '.tenant_id' < "$script_dir/../../output.json")
if [[ ${#TENANT_ID} -eq 0 ]]; then
  echo 'ERROR: Missing output value tenant_id' 1>&2
  exit 6
fi

AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID=$(jq -r '.aks_key_vault_secret_provider_client_id' < "$script_dir/../../output.json")
if [[ ${#AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID} -eq 0 ]]; then
  echo 'ERROR: Missing output value aks_key_vault_secret_provider_client_id' 1>&2
  exit 6
fi

#get information from Application Insights
APP_INSIGHTS_KEY=$(az resource show -g "${RESOURCE_GROUP}" -n "${APP_INSIGHTS}" --resource-type "microsoft.insights/components" --query properties.ConnectionString --output tsv)

#get information from Service Bus
SERVICE_BUS_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list --resource-group "${RESOURCE_GROUP}" --namespace-name "${SERVICE_BUS_NAMESPACE}" --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)

#get information from Cosmos DB
COSMOS_DB_ENDPOINT=$(az resource show -g "${RESOURCE_GROUP}" -n "${COSMOSDB_NAME}" --resource-type "microsoft.documentdb/databaseaccounts" --query properties.documentEndpoint --output tsv)
COSMOS_DB_KEY=$(az cosmosdb keys list -g "${RESOURCE_GROUP}" -n "${COSMOSDB_NAME}"  --query primaryMasterKey --output tsv)

#create env file for cargo-processing-api
cat << EOF > "$script_dir/../../src/cargo-processing-api/.env"
APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_KEY
APPLICATIONINSIGHTS_VERSION=3.4.7

#Service Bus Information
servicebus_connection_string=$SERVICE_BUS_CONNECTION_STRING
accelerator_queue_name=ingest-cargo

# Operation API
operations_api_url=http://operations-api:8081/
EOF
echo "CREATED: env file for CARGO-PROCESSING-API"

#create helm values file for cargo-processing-api
cat << EOF > "$script_dir/../../src/cargo-processing-api/helm/env.yaml"
image:
  repository: $ACR_NAME.azurecr.io/cargo-processing-api

keyVault:
  name: $KEYVAULT_NAME
  tenantId: $TENANT_ID

aksKeyVaultSecretProviderIdentityId: $AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID
EOF
echo "CREATED: helm value file for CARGO-PROCESSING-API"


#create env file for cargo-processing-validator
cat <<EOF > "$script_dir/../../src/cargo-processing-validator/.env"
APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_KEY
SERVICE_BUS_CONNECTION_STRING=$SERVICE_BUS_CONNECTION_STRING
QUEUE_NAME="ingest-cargo"
TOPIC_NAME="validated-cargo"
MAX_WAIT_TIME_IN_MS=1000
MAX_MESSAGE_DEQUEUE_COUNT=10
OPERATION_QUEUE_NAME="operation-state"
EOF
echo "CREATED: env file for CARGO-PROCESSING-VALIDATOR"

#create helm values file for cargo-processing-validator
cat << EOF > "$script_dir/../../src/cargo-processing-validator/helm/env.yaml"
image:
  repository: $ACR_NAME.azurecr.io/cargo-processing-validator

keyVault:
  name: $KEYVAULT_NAME
  tenantId: $TENANT_ID

aksKeyVaultSecretProviderIdentityId: $AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID
EOF
echo "CREATED: helm value file for CARGO-PROCESSING-VALIDATOR"


#create env file for invalid-cargo-manager
cat << EOF > "$script_dir/../../src/invalid-cargo-manager/.env"
SERVICE_BUS_CONNECTION_STR=$SERVICE_BUS_CONNECTION_STRING
SERVICE_BUS_TOPIC_NAME=validated-cargo
SERVICE_BUS_SUBSCRIPTION_NAME=invalid-cargo
SERVICE_BUS_QUEUE_NAME=operation-state
SERVICE_BUS_MAX_MESSAGE_COUNT=1
SERVICE_BUS_MAX_WAIT_TIME=30

COSMOS_DB_ENDPOINT=$COSMOS_DB_ENDPOINT
COSMOS_DB_KEY=$COSMOS_DB_KEY
COSMOS_DB_DATABASE_NAME=cargo
COSMOS_DB_CONTAINER_NAME=invalid-cargo

APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_KEY
CLOUD_LOGGING_LEVEL=INFO
CONSOLE_LOGGING_LEVEL=DEBUG

HEALTH_CHECK_SERVICE_BUS_DEGRADED_THRESHOLD_SECONDS=30
HEALTH_CHECK_SERVICE_BUS_UNHEALTHY_THRESHOLD_SECONDS=60
EOF
echo "CREATED: env file for INVALID-CARGO-MANAGER"

#create helm values file for invalid-cargo-manager
cat << EOF > "$script_dir/../../src/invalid-cargo-manager/helm/env.yaml"
image:
  repository: $ACR_NAME.azurecr.io/invalid-cargo-manager

keyVault:
  name: $KEYVAULT_NAME
  tenantId: $TENANT_ID

aksKeyVaultSecretProviderIdentityId: $AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID
EOF
echo "CREATED: helm value file for INVALID-CARGO-MANAGER"


#create env file for operations-api
cat << EOF > "$script_dir/../../src/operations-api/.env"
APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_KEY
APPLICATIONINSIGHTS_VERSION=3.4.7

# Service Bus Information
SERVICEBUS_CONNECTION_STRING=$SERVICE_BUS_CONNECTION_STRING
SERVICEBUS_PREFETCH_COUNT=10
OPERATION_STATE_QUEUE_NAME=operation-state

# Cosmos Db Information
COSMOS_DB_ENDPOINT=$COSMOS_DB_ENDPOINT
COSMOS_DB_KEY=$COSMOS_DB_KEY
COSMOS_DB_DATABASE_NAME=cargo
COSMOS_DB_CONTAINER_NAME=invalid-cargo
EOF
echo "CREATED: env file for OPERATIONS-API"

#create helm values file for operations-api
cat << EOF > "$script_dir/../../src/operations-api/helm/env.yaml"
image:
  repository: $ACR_NAME.azurecr.io/operations-api

keyVault:
  name: $KEYVAULT_NAME
  tenantId: $TENANT_ID

aksKeyVaultSecretProviderIdentityId: $AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID
EOF
echo "CREATED: helm value file for OPERATIONS-API"


#create appsettings.json file for valid-cargo-manager
cat <<EOF > "$script_dir/../../src/valid-cargo-manager/appsettings.json"
{
  "ApplicationInsights": {
    "ConnectionString": "$APP_INSIGHTS_KEY"
  },
  "ServiceBus": {
    "ConnectionString": "$SERVICE_BUS_CONNECTION_STRING",
    "Topic": "validated-cargo",
    "Queue": "operation-state",
    "Subscription": "valid-cargo",
    "PrefetchCount": 100,
    "MaxConcurrentCalls": 10
  },
  "CosmosDB": {
    "EndpointUri": "$COSMOS_DB_ENDPOINT",
    "PrimaryKey": "$COSMOS_DB_KEY",
    "Database": "cargo",
    "Container": "valid-cargo"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "HealthCheck": {
    "TcpServer": {
      "Port": 3030
    },
    "CosmosDB": {
      "MaxDurationMs": 200
    },
    "ServiceBus": {
      "MaxDurationMs": 200
    }
  }
}
EOF
echo "CREATED: appsettings.json file for VALID-CARGO-MANAGER"

#create helm values file for valid-cargo-manager
cat << EOF > "$script_dir/../../src/valid-cargo-manager/helm/env.yaml"
image:
  repository: $ACR_NAME.azurecr.io/valid-cargo-manager

keyVault:
  name: $KEYVAULT_NAME
  tenantId: $TENANT_ID

aksKeyVaultSecretProviderIdentityId: $AKS_KEY_VAULT_SECRET_PROVIDER_CLIENT_ID
EOF
echo "CREATED: helm value file for VALID-CARGO-MANAGER"
