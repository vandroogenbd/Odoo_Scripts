#!/bin/bash

# Options:
#	-h : list options
#	-o : echo command and copy it to clipboard then exit
#	-S : run as Python console environment
#	-c COMMUNITY_PATH : specify the root for the community branch
#	-e ENTERPRISE_PATH : specify the root for the enterprise branch
#	-b BRANCH_NAME : run Odoo from specified branch
#	-d DB_NAME : name of the db to run odoo with
#	-r : drop the db before starting the server
#	-i MODULES : install the specified modules (MODULES should be a comma-separated list)
#	-p PORT_NUMBER : specify the server port
#	-t TEST_TAGS : run the specified tests (TEST_TAGS should be a comma-separated list)
#	-l LOG_LEVEL : choose log level (choose from 'info', 'debug_rpc', 'warn', 'test', 'critical', 'runbot', 'debug_sql', 'error', 'debug', 'debug_rpc_answer', 'notset')
#	-u UPGRADE_PATH : path to the migrations folder of the upgrade scripts
#	-s : stop server after init

help_message="Options:
	-h : list options and exit
	-o : echo command and copy it to clipboard then exit
	-S : run as Python console environment
	-c COMMUNITY_PATH : specify the root for the community branch
	-e ENTERPRISE_PATH : specify the root for the enterprise branch
	-b BRANCH_NAME : run Odoo from specified branch
	-d DB_NAME : name of the db to run odoo with
	-r : drop the db before starting the server
	-i MODULES : install the specified modules (MODULES should be a comma-separated list)
	-p PORT_NUMBER : specify the server port
	-t TEST_TAGS : run the specified tests (TEST_TAGS should be a comma-separated list)
	-l LOG_LEVEL : choose log level (choose from 'info', 'debug_rpc', 'warn', 'test',
		'critical', 'runbot', 'debug_sql', 'error', 'debug', 'debug_rpc_answer', 'notset')
	-u UPGRADE_PATH : path to the migrations folder of the upgrade scripts
	-s : stop server after init

Examples:
	- Simply running the server
		> bash run_odoo.sh
	- Running tests from a specific module (results will be written to tests.log in the current working directory)
		> bash run_odoo.sh -i sale_timesheet -t sale_timesheet
	- Running a specific test function from a module (test functions must start with \"test_\")
		> bash run_odoo.sh -i sale_timesheet -t /sale_timesheet:TestClass.test_function
	- Running an upgrade script (will always run & upgrade to master)
		> bash run_odoo.sh -u ~/work/upgrade_master-opw-4309759-move_state_data-drod -s
"


# --- Default values ---

# Default community path
community_path="$HOME/work"
# Default enterprise path
enterprise_path="$HOME/work"
# Default branch name
branch=$(echo $(pwd) | awk -F/ '{print $NF}' | cut -d '_' -f 2-)
# Default db name
db_name="$(echo "$branch" | awk -F'-' '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+$/) print $i}')-$(basename "$branch" | grep -oP '\d+\.\d+' | head -n 1 | tr -d '.')"
# No modules by default
modules=""
# Drop db before running the server
drop_db=false
# Default port
port="8069"
# No test tags by default
test_tags=""
# Console Mode
console_mode=false
# Test Mode
test_mode=false
# Default log-level (empty uses Odoo default)
log_level=""
# No upgrade by default
upgrade=false
up_path=""
up_utils="$HOME/work/upgrade-util-master/src"
# Stop the server after init
stop=""
# Don't time-out (useful for debugging pruposes mostly)
limit="--limit-time-cpu 0 --limit-time-real 0"
# Default command to run
command="$community_path/community_$branch/odoo-bin --addons-path=$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/ -d $db_name --dev all $modules -p $port $test_tags $limit"

# --- Default values ---


# --- Argument parsing ---

# Reset OPTIND in case it has been used previously
OPTIND=1
# NOTE: Redirect error messages to STDERR with >&2!
while getopts ":h :o :S :c: :e: :b: :d: :r :p: :i: :l: :t: :u: :s" opt; do
	case $opt in
		h)
			echo "$help_message" >&2
			exit 0
			;;
		o)
			command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $test_tags $log_level $up_path $stop $limit"
			echo "$command" >&2
			echo "$command" | xclip -selection clipboard
			exit 0
			;;
		S)
			echo "Console mode"
			console_mode=true
			;;
		c)
			community_path=$OPTARG
			;;
		e)
			enterprise_path=$OPTARG
			;;
		b)
			branch=$OPTARG
			;;
		d)
			db_name=$OPTARG
			;;
		r)
			drop_db=true
			;;
		p)
			port=$OPTARG
			;;
		i)
			modules="-i $OPTARG"
			;;
		l)
			log_level="-log-level=$OPTARG"
			;;
		t)
			test_mode=true
			test_tags="--test-tags=$OPTARG --without-demo all"
			;;
		u)
			upgrade=true
			# Edit the upgrade path
			up_path="--upgrade-path=$OPTARG,$up_utils"
			;;
		s)
			# Stop after initialising the database
			stop="--stop-after-init"
			;;
		\?)
			echo "Unknown option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument" >&2
			exit 1
			;;
	esac
done


# --- Start the server ---

if $drop_db; then
	dropdb $db_name
	echo "DROPPED DB : $db_name"
fi

if $upgrade; then
	# Run the upgrade scripts
	command="$community_path/community-master/odoo-bin --addons-path="$community_path/community-master/addons/,$enterprise_path/enterprise-master/" -d $db_name --dev all $modules -p $port $up_path -u all $stop $limit"
	echo $command
	eval $command

elif $test_mode; then
	command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name $modules -p $port $test_tags  --stop-after-init $log_level $limit"
	echo "Running the following command:

	$command

Logs will be written to tests.log in the current working directory..."
	eval $command > tests.log 2>&1
	echo "Finished tests, opening log in Codium."
	codium tests.log

elif $console_mode; then
	command="$community_path/community_$branch/odoo-bin shell --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name $modules $limit --without-demo=true"
	echo $command
	eval $command

else
	command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $test_tags $log_level $stop $limit --without-demo=False"
	echo $command
	eval $command
fi
