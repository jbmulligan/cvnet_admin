#!/bin/bash

source install_helpers.sh

if [[ $# -ne 2 ]]; then
	echo "Usage:  ./update_service.sh service_name version"
	exit 1
fi

SVC_NAME=$1
export SVC_NAME

echo "update_service.sh $SVC_NAME BEGIN"

version=$2

check_deployment
ensure_log_dir
set_service_vars
set_env_vars
substitute_vars
ensure_tusd_link

echo "update_service.sh $SVC_NAME DONE"

