#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo "Usage:  deploy.sh <version_string>"
	exit 1
fi

vers=$1

dist_dir=$HOME/distributions
if [[ ! -e $dist_dir ]]; then
	echo "Distribution directory $dist_dir does not exist."
	exit 1
fi
if [[ ! -d $dist_dir ]]; then
	echo "$dist_dir exists but is not a directory."
	exit 1
fi

distfile=$dist_dir/hub-$vers.tgz
if [[ ! -e $distfile ]]; then
	echo "Distribution file $distfile not found."
	exit 1
fi

if [[ -e $vers ]]; then
	echo "A deployment of $vers already exists; not unpacking distribution."
else
	mkdir $vers
	cd $vers
	echo "Unpacking $distfile ..."
	tar xfz $distfile > /dev/null 2>&1
	cd ..
fi


