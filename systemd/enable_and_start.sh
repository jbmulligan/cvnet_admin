#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo Usage: ./enable_and_start.sh short_hostname
	exit
fi

svc=$1.service
if [[ ! -e $svc ]]; then
	echo ''
	echo ERROR: no service definition file $svc
	echo ''
	exit 1
fi

sudo systemctl daemon-reload
sudo systemctl enable $svc
sudo systemctl start $svc

