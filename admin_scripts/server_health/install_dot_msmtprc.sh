#!/bin/bash

install_for_user(){

	if [ $# -ne 1 ]; then
		echo usage:  install_for_user username
		exit 1
	fi

	user=$1
	user_home=`eval echo "~$user"`

	echo Installing in $user_home...
	if [ $user = "root" ]; then
		sudo cp dot_msmtprc $user_home/.msmtprc
	else
		cp dot_msmtprc $user_home/.msmtprc
	fi
}

install_for_user root

if [ -z $TELLAB_ADMIN_USER ]; then
	echo TELLAB_ADMIN_USER is not defined
	exit 1
fi

install_for_user $TELLAB_ADMIN_USER

