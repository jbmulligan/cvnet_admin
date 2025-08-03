#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo Usage: ./relaunch_tusd.sh service_name version
	exit
fi

svc=$1
vers=$2

# we should not need to kill the old process - systemctl should do it for us?

sudo systemctl daemon-reload
sudo systemctl restart $svc


