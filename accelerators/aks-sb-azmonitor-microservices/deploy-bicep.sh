#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function help() {
	echo
	echo "deploy-bicep.sh"
	echo
	echo "Deploy sample via Bicep"
	echo
	echo -e "\t--skip-helm-deploy\t(Optional)Skip Helm deployment of services to AKS"
	echo -e "\t--aks-aad-auth\t(Optional)Enable AAD authentication for AKS"
	echo
}


# Set default values here
SKIP_HELM_DEPLOY=false
AKS_AAD_AUTH=false


# Process switches:
SHORT=h
LONG=skip-helm-deploy,aks-aad-auth,help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
	case "$1" in
		--skip-helm-deploy)
			SKIP_HELM_DEPLOY=true
			shift 1
			;;
		--aks-aad-auth )
			AKS_AAD_AUTH=true
			shift 1
			;;
		-h | --help)
			help
			exit 0
			;;
		--)
			shift;
			break
			;;
		*)
			echo "Unexpected '$1'"
			help
			exit 1
			;;
	esac
done

if [[ -z $IN_CD ]]; then # skip loading env vars if running in CD (as they are already set)
	if [[ ! -f "$script_dir/.env" ]]; then
		echo "Please create a .env file (using .env.sample as a starter)" 1>&2
		exit 1
	fi
	source "$script_dir/.env"
fi

if [[ -z "$USERNAME" ]]; then
	echo 'USERNAME not set - ensure you have specifed a value for it in your .env file' 1>&2
	exit 6
fi

if [[ -z "$EMAIL_ADDRESS" ]]; then
	echo 'EMAIL_ADDRESS not set - ensure you have specifed a value for it in your .env file' 1>&2
	exit 6
fi

deploy_args=()
if [[ "$AKS_AAD_AUTH" == "true" ]]; then
	deploy_args+=(--aks-aad-auth)
fi

# Set default values
LOCATION=${LOCATION:-eastus}

figlet infra
echo "Starting Bicep deployment to $LOCATION"
echo "${deploy_args[@]}" | xargs "$script_dir/infrastructure/scripts/deploy-bicep-infrastructure.sh" --username "$USERNAME" --email-address "$EMAIL_ADDRESS" --location "$LOCATION"
echo "Bicep deployment completed"

figlet images
echo "Building and pushing service images"
ACR_NAME=$(jq -r '.acr_name' < "$script_dir/output.json")
if [[ ${#ACR_NAME} -eq 0 ]]; then
	echo 'ERROR: Missing output value acr_name' 1>&2
	exit 6
fi
"$script_dir/infrastructure/scripts/build-and-push-images.sh" --acr-name "$ACR_NAME" --image-tag latest

figlet env
echo "Creating env files"
"$script_dir/infrastructure/scripts/create-env-files-from-output.sh"

if [[ "$SKIP_HELM_DEPLOY" == "true" ]]; then
	echo "Skipping Helm deployment"
else
	figlet services
	echo "Deploying services"
	echo "${deploy_args[@]}" | xargs "$script_dir/infrastructure/scripts/deploy-helm-charts.sh"
fi

echo "Deployment completed"
