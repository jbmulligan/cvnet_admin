
# helper functions used by install_page.sh and install_api.sh

subst_var(){
	if [[ $# -ne 1 ]]; then
		echo "Usage: subst_var env_var_name"
		exit 1
	fi

	cmd="val=\$$1"
	eval "$cmd"

	if [[ -z $val ]]; then
		# We used to exit with an error here, but
		# if something (like PREREQ) is undefined,
		# then we want to remove it!
		# It is preferable to use conditional substitution,
		# as has been done for TUSD_PORT.
		echo "Alert:  \$$1 is not defined, removing from service file"
		cat $tmp_input | grep -v "XXX_${1}_XXX" > $tmp_output
	else
		# note use of ? instead of / ...
		cat $tmp_input | sed -e "s?XXX_${1}_XXX?$val?g" > $tmp_output
	fi
	mv $tmp_output $tmp_input
}

# It is assumed that this is called with the name of an upload service
get_api_svc_name(){
	if [[ $# -ne 1 ]]; then
		echo "Usage:  get_api_svc_name <page_svc_name>"
		exit 1
	fi
	nf=`echo $1 | awk -F '-uploads' '{print NF}'`
	if [[ $nf -ne 2 ]]; then
		echo "ERROR: get_api_svc_name $1: not an upload service name"
		exit 1
	fi
	base=`echo $1 | awk -F '-uploads' '{print $1}'`
	api_svc_name=${base}-api
}

# Assumes called with name of a page service
get_upload_svc_name(){
	if [[ $# -ne 1 ]]; then
		echo "Usage:  get_upload_svc_name <page_svc_name>"
		exit 1
	fi
	nf=`echo $1 | awk -F '-page' '{print NF}'`
	if [[ $nf -ne 2 ]]; then
		echo "ERROR: get_upload_svc_name $1: not a page service name"
		exit 1
	fi
	base=`echo $1 | awk -F '-page' '{print $1}'`
	upload_svc_name=${base}-uploads
}

set_service_vars(){
	case $SVC_NAME in
		*-api)
			SERVER_DIR="$deployment_dir/$version/apiServer"
			SVC_DESCRIPTION="CVNet API server $SVC_NAME"
			PREREQ_SVC_NAME=mongod
			APP_JS=api-server.js
			;;
		*-page)
			SERVER_DIR="$deployment_dir/$version/pageServer"
			SVC_DESCRIPTION="CVNet page server $SVC_NAME"
			get_upload_svc_name $SVC_NAME
			PREREQ_SVC_NAME=$upload_svc_name
			APP_JS=page-server.js
			;;
		*-uploads)
			SERVER_DIR="$deployment_dir/$version/uploadServer/tusd"
			SVC_DESCRIPTION="CVNet upload server $SVC_NAME"
			get_api_svc_name $SVC_NAME
			PREREQ_SVC_NAME=$api_svc_name
			is_upload_server=1
			;;
		*)
			echo "Unexpected service name '$SVC_NAME'"
			exit 1
			;;
	esac

	export SERVER_DIR
	export SVC_DESCRIPTION
}

check_deployment(){
	deployment_dir=$HOME/cvnet_admin/deployments
	if [[ ! -e $deployment_dir ]]; then
		echo "Error:  deployment dir $deployment_dir does not exist."
		exit 1
	elif [[ ! -e $deployment_dir/$version ]]; then
		pushd $deployment_dir > /dev/null
		./deploy.sh $version
		if [[ $? -ne 0 ]]; then
			echo "Failed to install $version for deployment;"
			echo "Make sure that $version has been distributed."
			exit 1
		fi
		popd > /dev/null
	else
		echo "Version $version has already been deployed."
	fi
}

ensure_log_dir(){
	log_base=$HOME/logs
	if [[ ! -e $log_base ]]; then
		echo "Directory $log_base does not exist, creating..."
		mkdir $log_base
	fi
	log_dir=$log_base/$SVC_NAME
	if [[ ! -e $log_dir ]]; then
		echo "Directory $log_dir does not exist, creating..."
		mkdir $log_dir
	else
		echo "Directory $log_dir already exists."
	fi
}

set_env_vars(){
	export NODE_BIN=`which node | sed -e 's/\/node$//'`
	export SPHINX_BIN=`which sphinx-build | sed -e 's/\/sphinx-build$//'`
	export LOG_DIR="$log_dir"

	NODE_ENV=production	# what else could this be?
	USERNAME=jbmull
	GROUPNAME=jbmull

	CWD=`pwd`
	CVNET_ADMIN_DIR=$CWD/..
}

set_port_from_svc(){
	case $SVC_NAME in
		lab2-dev-uploads)
			TUSD_PORT=1081
			;;
		lab2-prod-uploads)
			TUSD_PORT=1080
			;;
		*)
			echo "Unrecognized upload service: $SVC_NAME"
			TUSD_PORT=1080
			;;
	esac
}
	
substitute_vars(){
	outfile=$SVC_NAME.service
	if [[ -z $is_upload_server ]]; then
		infile=svc_template
	else
		infile=upload_template
		set_port_from_svc
	fi
	tmp_input=/tmp/tmp_input.$$
	tmp_output=/tmp/tmp_output.$$

	cp $infile $tmp_input
	subst_var SVC_NAME
	subst_var PREREQ_SVC_NAME
	subst_var SVC_DESCRIPTION
	subst_var USERNAME
	subst_var GROUPNAME
	subst_var SERVER_DIR
	subst_var NODE_BIN
	subst_var SPHINX_BIN
	subst_var NODE_ENV
	subst_var LOG_DIR
	subst_var CVNET_ADMIN_DIR
	subst_var CWD
	if [[ -z $is_upload_server ]]; then
		subst_var APP_JS
	else
		subst_var TUSD_PORT
	fi

	n_unsub=`cat $tmp_input | grep XXX | wc -l | sed -e "s' ''g"`
	if [[ $n_unsub -gt 0 ]]; then
		echo "Error:  some un-substituted variables remain:"
		cat $tmp_input | grep XXX | awk -F 'XXX_' '{print $2}' \
			| awk -F '_XXX' '{print $1}'
		exit 1
	fi

	mv $tmp_input $outfile
}


fatal_error(){
	echo "FATAL: $1"
	exit 1
}

ensure_tusd_link(){
	# this directory should already exist, and probably is a symlink
	# to a large secondary storage volume.
	tusd_data_dir=$HOME/tusd_data
	if [[ ! -e $tusd_data_dir ]]; then
		echo \
		"WARNING: Directory $tusd_data_dir does not exist, creating..."
		mkdir $tusd_data_dir
	fi
	# find the deployment dir - $deployment_dir, $SVC_NAME and $version
	# should be set...
	if [[ -z $deployment_dir ]]; then
		fatal_error "deployment_dir is not set"
	fi
	if [[ -z $version ]]; then
		fatal_error "version is not set"
	fi
	tusd_dir=$deployment_dir/$version/uploadServer/tusd
	if [[ ! -e $tusd_dir ]]; then
		fatal_error "$tusd_dir not exist"
	fi
	tusd_data_target=$tusd_dir/data
	if [[ -e $tusd_data_target ]]; then
		echo "$tusd_data_target already exists"
		return
	fi
	tusd_data_src=$HOME/tusd_data
	if [[ ! -e $tusd_data_src ]]; then
		fatal_error "$tusd_data_src does not exist"
	fi
	ln -s $tusd_data_src $tusd_data_target
}

