#!/bin/bash
set -e

#
# This script generates the bicep parameters file and then uses that to deploy the infrastructure
# An output.json file is generated in the project root containing the outputs from the deployment
# The output.json format is consistent between Terraform and Bicep deployments
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

help()
{
    echo ""
      echo "<This command will deploy the whole required infrastructure for this project by using Bicep>"
      echo ""
      echo "Command"
      echo "    deploy-bicep-infrastructure.sh : Will deploy all required services services."
      echo ""
      echo "Arguments"
      echo "    --username, -u      : REQUIRED: Unique name to assign in all deployed services, your high school hotmail alias is a great idea!"
      echo "    --email-address, -e : REQUIRED: Email address for alert notifications"
      echo "    --location, -l      : REQUIRED: Azure region to deploy to"
      echo "    --aks-aad-auth      : OPTIONAL Enable AAD authentication for AKS"
      echo ""
      exit 1
}

SHORT=u:,l:,h
LONG=username:,email-address:,location:,aks-aad-auth,help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

USERNAME=''
LOCATION=''
EMAIL_ADDRESS=''
AKS_AAD_AUTH=false
while :
do
  case "$1" in
    -u | --username )
      USERNAME="$2"
      shift 2
      ;;
    -e | --email-address )
      EMAIL_ADDRESS="$2"
      shift 2
      ;;
    -l | --location )
      LOCATION="$2"
      shift 2
      ;;
    --aks-aad-auth )
      AKS_AAD_AUTH=true
      shift 1
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

if [[ ${#USERNAME} -eq 0 ]]; then
  echo 'ERROR: Missing required parameter --username | -u' 1>&2
  exit 6
fi

if [[ ${#EMAIL_ADDRESS} -eq 0 ]]; then
  echo 'ERROR: Missing required parameter --email-address | -e' 1>&2
  exit 6
fi

if [[ ${#LOCATION} -eq 0 ]]; then
  echo 'ERROR: Missing required parameter --location | -l' 1>&2
  exit 6
fi


if [[ "$AKS_AAD_AUTH" == true ]]; then
  if [[ -z "$ARM_CLIENT_ID" ]]; then
    # Get the ID of the currently signed in user
    current_user_object_id=$(az ad signed-in-user show --query id -o tsv)
  else
    # Get the ID of the service principal for ARM_CLIENT_ID
    current_user_object_id=$(az ad sp show --id "$ARM_CLIENT_ID" --query id -o tsv)
  fi
  echo "Enabling AKS AAD authentication (current user object ID: $current_user_object_id)"
fi

cat << EOF > "$script_dir/../bicep/azuredeploy.parameters.json"
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "${LOCATION}"
    },
    "uniqueUserName": {
      "value": "${USERNAME}"
    },
    "cosmosDatabaseName": {
      "value": "cargo"
    },
    "cosmosContainer1Name": {
      "value": "valid-cargo"
    },
    "cosmosContainer2Name": {
      "value": "invalid-cargo"
    },
    "cosmosContainer3Name": {
      "value": "operations"
    },
    "serviceBusQueue1Name": {
      "value": "ingest-cargo"
    },
    "serviceBusQueue2Name": {
      "value": "operation-state"
    },
    "serviceBusTopicName": {
      "value": "validated-cargo"
    },
    "serviceBusSubscription1Name": {
      "value": "valid-cargo"
    },
    "serviceBusSubscription2Name": {
      "value": "invalid-cargo"
    },
    "serviceBusTopicRule1Name": {
      "value": "valid"
    },
    "serviceBusTopicRule2Name": {
      "value": "invalid"
    },
    "aksAadAuth": {
      "value": $AKS_AAD_AUTH
    },
    "aksAadAdminUserObjectId" : {
      "value": "$current_user_object_id"
    },
    "notificationEmailAddress": {
      "value": "${EMAIL_ADDRESS}"
    }
  }
}
EOF

echo "Bicep parameters file created"

cd "$script_dir/../bicep/"

deployment_name="deployment-${USERNAME}-${LOCATION}"
echo "Starting Bicep deployment ($deployment_name)"
az deployment sub create \
  --location "$LOCATION" \
  --template-file main.bicep \
  --name "$deployment_name" \
  --parameters azuredeploy.parameters.json \
  --output json \
  | jq "[.properties.outputs | to_entries | .[] | {key:.key, value: .value.value}] | from_entries" > "$script_dir/../../output.json"

echo "Bicep deployment completed"
