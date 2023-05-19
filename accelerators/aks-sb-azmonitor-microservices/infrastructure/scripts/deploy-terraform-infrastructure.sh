#!/bin/bash
set -e

#
# This script generates the terraform.tfvars file and then uses that to deploy the infrastructure
# An output.json file is generated in the project root containing the outputs from the deployment
# The output.json format is consistent between Terraform and Bicep deployments
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

help()
{
    echo ""
      echo "<This command will deploy the whole required infrastructure for this project by using Terraform>"
      echo ""
      echo "Command"
      echo "    deploy-terraform-infrastructure.sh : Will deploy all required services."
      echo ""
      echo "Arguments"
      echo "    --username, -u : REQUIRED: Unique name to assign in all deployed services, your high school hotmail alias is a great idea!"
      echo "    --email-address, -e : REQUIRED: Email address for alert notifications"
      echo "    --location, -l : REQUIRED: Azure region to deploy to"
      echo "    --aks-aad-auth : OPTIONAL Enable AAD authentication for AKS"
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

current_user_object_id=""
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

cat << EOF > "$script_dir/../terraform/terraform.tfvars"
location                        = "${LOCATION}"
prefix                          = "dev"
unique_username                 = "${USERNAME}"
cosmosdb_database_name          = "cargo"
cosmosdb_container1_name        = "valid-cargo"
cosmosdb_container2_name        = "invalid-cargo"
cosmosdb_container3_name        = "operations"
service_bus_queue1_name         = "ingest-cargo"
service_bus_queue2_name         = "operation-state"
service_bus_topic_name          = "validated-cargo"
service_bus_subscription1_name  = "valid-cargo"
service_bus_subscription2_name  = "invalid-cargo"
service_bus_topic_rule1_name    = "valid"
service_bus_topic_rule2_name    = "invalid"
aks_aad_auth                    = ${AKS_AAD_AUTH}
aks_aad_admin_user_object_id    = "${current_user_object_id}"
notification_email_address      = "${EMAIL_ADDRESS}"
EOF

echo -e "\n*** Terraform parameters file created"

cd "$script_dir"/../terraform/

if [[ -n "$TERRAFORM_STATE_STORAGE_ACCOUNT_NAME" ]]; then
  # init with Azure backend
  echo -e "\n*** Initializing Terraform (with Azure backend: $TERRAFORM_STATE_STORAGE_ACCOUNT_NAME)"
cat > backend.tf << EOF
terraform {
  backend "azurerm" {}
}
EOF
  terraform init -upgrade \
    -backend-config "resource_group_name=${TERRAFORM_STATE_RESOURCE_GROUP_NAME}" \
    -backend-config "storage_account_name=${TERRAFORM_STATE_STORAGE_ACCOUNT_NAME}" \
    -backend-config "container_name=${TERRAFORM_STATE_CONTAINER_NAME}" \
    -backend-config "key=${TERRAFORM_STATE_KEY}"
else
  # init with local backend
  echo -e "\n*** Initializing Terraform (with local backend)"
  rm -rf backend.tf
  terraform init -upgrade
fi

echo -e "\n*** Planning Terraform resources"

terraform plan -var-file=terraform.tfvars -out=plan.out

echo -e "\n*** Deploying Terraform resources"

terraform apply "plan.out"

echo -e "\n*** Gathering required outputs"

terraform output -json | jq "[. | to_entries | .[] | {key:.key, value: .value.value}] | from_entries" > "${script_dir}/../../output.json"
