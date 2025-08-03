#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo Usage: ./relaunch_service.sh service_name version
	exit
fi

svc=$1
vers=$2

server_type=`grep $svc serverTypesByService.txt | awk -F '	' '{print $2}'`
echo server_type = $server_type

# the page and api services are run with forever...

if [[ $server_type == "tusd" ]]; then
	echo "Launching upload server $svc $vers"
	./relaunch_tusd.sh $svc $vers 
	exit
fi

n_matches=`forever list | grep $svc | wc -l`
if [[ $n_matches -lt 1 ]]; then
	echo "No forever process found for $svc"
elif [[ $n_matches -gt 1 ]]; then
	echo "Found $n_matches forever processes found for $svc!?"
	exit 1
else
	svc_info=`forever list | grep $svc`
	echo svc_info = $svc_info
	code=`echo $svc_info | awk -F ' ' '{print $3}'`
	echo code = $code
	forever stop $code
fi

if [[ $server_type == "apiServer" ]]; then
	server_prog=api-server.js
elif [[ $server_type == "pageServer" ]]; then
	server_prog=page-server.js
elif [[ $server_type == "wwwServer" ]]; then
	server_prog=www-server.js
else
	echo "Unexpected server_type '$server_type'"
	exit 1
fi

log_dir=$HOME/logs/$svc

if [[ ! -e $log_dir ]]; then
	echo "Directory $log_dir does not exist."
	exit 1
fi

if [[ -z $CVNET_ADMIN_DIR ]]; then
	echo CVNET_ADMIN_DIR is not defined
	exit 1
fi

deployment_dir=$CVNET_ADMIN_DIR/deployments/$vers
if [[ ! -e $deployment_dir ]]; then
	echo Directory $deployment_dir does not exist.
	echo Version $vers has not been deployed.
	exit 1
fi

server_dir=$deployment_dir/$server_type
if [[ ! -e $server_dir ]]; then
	echo Directory $server_dir does not exist.
	exit 1
fi

now=`date`
printf "\n\n$now relaunch_service.sh: Relaunching $svc with version $vers\n\n" >> $log_dir/out.log

cd $server_dir
if [[ $server_type == pageServer ]]; then
	./prepare_svc.sh $svc
fi

pwd
# spinSleepTime option added to prevent it from going into STOPPED state???
forever --spinSleepTime 5000 $server_prog $svc >> $log_dir/out.log 2>> $log_dir/err.log &


