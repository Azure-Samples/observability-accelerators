#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function help() {
	echo
	echo "build-images.sh"
	echo
	echo "Build images"
	echo
	echo -e "\t--acr-name\t(Optional)The name of the Azure Container Registry to push to. If not provided, the images will be built but not pushed."
	echo -e "\t--image-tag\t(Optional)The tag to build the image with (defaults to 'latest')"
	echo
}


# Set default values here
acr_name=""
image_tag="latest"


# Process switches:
SHORT=h
LONG=acr-name:,image-tag:,help
OPTS=$(getopt -a -n files --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
	case "$1" in
		--acr-name)
			acr_name=$2
			shift 2
			;;
		--image-tag)
			image_tag=$2
			shift 2
			;;
		-h | --help)
			help
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

image_base_name=""
if [[ -n $acr_name ]]; then
	echo -e "**\n** Authenticating to container registry ($acr_name)...\n**"
	az acr login --name "$acr_name"

	image_base_name="${acr_name}.azurecr.io/"
fi


services_to_build=("cargo-processing-api" "cargo-processing-validator" "invalid-cargo-manager" "operations-api" "valid-cargo-manager")
for service in "${services_to_build[@]}"
do
	echo
	echo "*******************************************************************************************************************"
	echo -e "\n**\n** Building ${service}...\n**"
	echo "*******************************************************************************************************************"
	docker build --progress plain  -t "${image_base_name}${service}:${image_tag}" "$script_dir/../../src/${service}"

	if [[ -n $acr_name ]]; then
		echo -e "\n**\n** Pushing ${service}...\n**"
		docker push "${image_base_name}${service}:${image_tag}"
	fi
done
