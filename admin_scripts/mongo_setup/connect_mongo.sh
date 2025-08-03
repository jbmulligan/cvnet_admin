#!/bin/bash
#
# Create a script to be read by the mongo shell to create a user.
# Originally, these scripts were crafted by hand; this new approach has
# been taken in order to use a single source of password data.

if [[ $# -ne 2 ]]; then
	echo usage:  ./connect_mongo.sh host user/admin/root
	exit 1
fi

host=$1
level=$2

. mongo_passwords.sh $host $level

echo Command:  "mongo --host $host --username=$TELLAB_DB_USERNAME --password=$TELLAB_DB_PW $TELLAB_DATABASE"
mongo --host $host --username=$TELLAB_DB_USERNAME --password=$TELLAB_DB_PW $TELLAB_DATABASE

