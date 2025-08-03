#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo 'usage:  ./link_file.sh short_hostname (or "domain")'
	exit 1
fi

if [[ $1 == "domain" ]]; then
	hn=tellab.org
else
	hn=$1.tellab.org
fi

filename=$hn.conf

if [[ ! -e $filename ]]; then
	echo Error:  file $filename does not exist
	exit 1
fi

d=`pwd`
config_dir=/etc/nginx/conf.d

if [[ ! -e $config_dir/$filename ]]; then
	echo Creating link $config_dir/$filename ...
	cd $config_dir
	sudo ln -s $d/$filename $filename
	cd $d
else
	echo Link $config_dir/$filename already exists
fi

echo ''
ls -l $config_dir/$filename


