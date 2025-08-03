#!/bin/bash

if [[ $# -ne 1 ]]; then
	echo Usage: ./link_service.sh short_hostname
	exit
fi

hn=$1

d=`pwd`
src=$d/$hn.service
target=/lib/systemd/system/$hn.service

get_file_mode(){
	ls_out=`ls -l $1`
	mode=`echo $ls_out | awk -F ' ' '{print $1}'`
}

get_link_target(){
	ls_out=`ls -l $1`
	link_target=`echo $ls_out | awk -F '-> ' '{print $2}'`
}

require_to_be_link(){
	get_file_mode $1	# returns in $mode
	# BUG?  should be rwxr-xr-x !?
	if [[ $mode != lrwxrwxrwx ]]; then
		echo "Target $1 exists, but does not appear to be a symlink."
		echo $ls_out
		exit 1
	fi
}

if [[ ! -e $src ]]; then
	echo ''
	echo ERROR: File $src does not exist.
	echo ''
	echo Make sure that the hostname is correct and that you are running
        echo this script from the proper location '(cvnet_admin/systemd)'
	echo ''
	exit 1
elif [[ -e $target ]]; then
	# the target exists; if it points here, then all is OK
	require_to_be_link $target
	get_link_target $target
	if [[ $link_target == $src ]]; then
		echo Link $target already points to $src
		exit 0
	fi

	echo "Link $target exists, but does not point to $src; will remove it."
	sudo rm $target

	# The old version may also be linked in /etc/systemd, and that
	# one needs to be removed also before the new settings will be
	# effective!?  It appears to be sufficient to simply remove it,
	# and the system will re-create it when needed...

	target=/etc/systemd/system/$hn.service
	get_file_mode $target
	if [[ $mode != lrwxrwxrwx ]]; then
		echo "Target $1 exists, but does not appear to be a symlink."
		echo $ls_out
	else
		get_link_target $target
		if [[ $link_target == $src ]]; then
			echo Link $target already points to $src
		else
			echo Link $target does not point to $src, will remove
			sudo rm $target
		fi
	fi

fi

echo "Creating link $target pointing to $src..."
sudo ln -s $src $target
ls -l $target

