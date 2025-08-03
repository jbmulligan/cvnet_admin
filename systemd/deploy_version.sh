#!/bin/bash

source install_helpers.sh

if [[ $# -ne 1 ]]; then
	echo "Usage:  ./deploy_version.sh version"
	exit 1
fi

version=$1

check_deployment

