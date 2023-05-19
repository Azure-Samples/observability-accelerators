#!/bin/bash
set -e

#
# This script expects to find an output.json in the project root with the values
# from the infrastructure deployment.
# It deploys helm charts for each service to the AKS cluster
#

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


function help() {
	echo
	echo "deploy-helm-charts.sh"
	echo
	echo "Deploy solution into AKS using Helm"
	echo
	echo -e "\t--aks-aad-auth\t(Optional)Enable AAD authentication for AKS"
	echo
}


# Set default values here
AKS_AAD_AUTH=false


# Process switches:
SHORT=h
LONG=aks-aad-auth,help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
	case "$1" in
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


RESOURCE_GROUP=$(jq -r '.rg_name' < "$script_dir/../../output.json")
if [[ ${#RESOURCE_GROUP} -eq 0 ]]; then
  echo 'ERROR: Missing output value rg_name' 1>&2
  exit 6
fi

AKS_NAME=$(jq -r '.aks_name' < "$script_dir/../../output.json")
if [[ ${#AKS_NAME} -eq 0 ]]; then
  echo 'ERROR: Missing output value aks_name' 1>&2
  exit 6
fi


if [[ "$AKS_AAD_AUTH" == "true" ]]; then
  echo "Getting Admin AKS credentials"
  # Temporarily get cluster admin credentials to set up user permisions for default namespace

  # Get kubeconfig for the AKS cluster
  az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --admin --overwrite-existing
  # Update the kubeconfig to use  https://github.com/azure/kubelogin
  kubelogin convert-kubeconfig -l azurecli

  if [[ -z "$ARM_CLIENT_ID" ]]; then
    # Get the UPN of the currently signed in user
    current_user_object_id=$(az ad signed-in-user show --query id -o tsv)
  else
    # Get the ID of the service principal for ARM_CLIENT_ID
    current_user_object_id=$(az ad sp show --id "$ARM_CLIENT_ID" --query id -o tsv)
  fi

  echo "Adding user-full-access role & binding"
cat <<EOF | kubectl apply -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: user-full-access
  namespace: default
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${current_user_object_id}-user-access
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: user-full-access
subjects:
- kind: User
  namespace: default
  name: $current_user_object_id
EOF
  echo "Adding cluster-admin role binding"
cat <<EOF | kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${current_user_object_id}-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: $current_user_object_id
  apiGroup: rbac.authorization.k8s.io
EOF

fi

echo "Getting AKS credentials"
# Get kubeconfig for the AKS cluster
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing
# Update the kubeconfig to use  https://github.com/azure/kubelogin
kubelogin convert-kubeconfig -l azurecli

charts_to_deploy=("cargo-processing-api" "cargo-processing-validator" "invalid-cargo-manager" "operations-api" "valid-cargo-manager")
for chart in "${charts_to_deploy[@]}"
do
	echo -e "\n**\n** Deploying ${chart}...\n**"
	helm upgrade \
		--install  "$chart" "$script_dir/../../src/$chart/helm" \
		--values "$script_dir/../../src/$chart/helm/$chart.yaml" \
		--values "$script_dir/../../src/$chart/helm/env.yaml" \
		--wait
done


echo -e "\n**\n** Deploying ingress-nginx ...\n**"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade \
	--install ingress-nginx \
	ingress-nginx/ingress-nginx \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/actuator/health \
	--wait

echo -e "\n**\n** Deploying solution-level chart ...\n**"
helm upgrade \
	--install aks-sb-azmonitor-microservices "$script_dir/../../src/solution/helm" \
	--wait


ingress_ip=""
while true; do
    ingress_ip=$(kubectl get ingress aks-sb-azmonitor-microservices --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
	if [[ -n "$ingress_ip" ]]; then
		break
	fi
    echo "Waiting for ingress IP..."
	sleep 10
done

echo "Ingress IP: $ingress_ip"

#create env file for http docs
cat << EOF > "$script_dir/../../http/.env"
SERVICE_IP=$ingress_ip
EOF
echo "CREATED: env file for http docs"



#get information from Service Bus
SERVICE_BUS_NAMESPACE=$(jq -r '.sb_namespace_name' < "$script_dir/../../output.json")
if [[ ${#SERVICE_BUS_NAMESPACE} -eq 0 ]]; then
  echo 'ERROR: Missing output value sb_namespace_name' 1>&2
  exit 6
fi
SERVICE_BUS_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list --resource-group "${RESOURCE_GROUP}" --namespace-name "${SERVICE_BUS_NAMESPACE}" --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)



#create env file for cargo-test-scripts
cat << EOF > "$script_dir/../../src/cargo-test-scripts/.env"
SERVICEBUS_CONNECTION_STRING=$SERVICE_BUS_CONNECTION_STRING
QUEUE_NAME=ingest-cargo
TOPIC_NAME=validated-cargo
CARGO_PROCESSING_API_URL=http://$ingress_ip/cargo
OPERATIONS_API_URL=http://$ingress_ip/cargo

EOF
echo "CREATED: env file for CARGO-TEST-SCRIPTS"
