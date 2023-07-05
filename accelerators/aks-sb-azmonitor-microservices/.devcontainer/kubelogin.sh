#!/bin/bash
set -e

wget -O /tmp/kubelogin-linux-amd64.zip \
	https://github.com/Azure/kubelogin/releases/download/v0.0.24/kubelogin-linux-amd64.zip

unzip /tmp/kubelogin-linux-amd64.zip -d /tmp/kubelogin

cp /tmp/kubelogin/bin/linux_amd64/kubelogin "/home/$USERNAME/.local/bin/kubelogin"
