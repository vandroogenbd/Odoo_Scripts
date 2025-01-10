#!/bin/bash

# Options:
#	-h : list options
#	-o : echo command and copy it to clipboard then exit
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
		> bash run_odoo.sh -i sale_timesheet -t /sale_timesheet:TestClass.test_function"


# --- Default values ---

# Default community path
community_path="~/work"
# Default enterprise path
enterprise_path="~/work"
# Default branch name
branch=$(echo $(pwd) | awk -F/ '{print $NF}' | cut -d '_' -f 2-)
# Default db name
db_name="db-$branch"
# No modules by default
modules=""
# Default port
port="8069"
# No test tags by default
test_tags=""
# Test Mode
test_mode=false
# Default log-level (empty uses Odoo default)
log_level=""
# No upgrade by default
upgrade=false
up_path=""
up_utils="~/work/upgrade-util-master/src"
# Stop the server after init
stop=""
# Default command to run
command="$community_path/community_$branch/odoo-bin --addons-path=$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/ -d $db_name --dev all $modules -p $port $test_tags"

# --- Default values ---


# --- Argument parsing ---

# Reset OPTIND in case it has been used previously
OPTIND=1
# NOTE: Redirect error messages to STDERR with >&2!
while getopts ":h :o :c: :e: :b: :d: :r :p: :i: :l: :t: :u: :s" opt; do
	case $opt in
		h)
			echo "$help_message" >&2
			exit 0
			;;
		o)
			command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $test_tags $log_level $up_path $stop"
			echo "$command" >&2
			echo "$command" | xclip -selection clipboard
			exit 0
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
			(dropdb $db_name || true)
			echo "DROPPED DB : $db_name"
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
			test_tags="--test-tags=$OPTARG"
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

if $upgrade; then
	# Run the upgrade scripts
	command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $up_path $stop"
	eval $command

elif $test_mode; then
	# Run the tests with a "fresh" testing db
	db_name="db-test"
	(dropdb $db_name || true) >&2
	# Check if log level was specified, otherwise use "error"
	if [[ ! $log_level ]]; then
		log_level="--log-level=error"
	fi
	command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $test_tags  --stop-after-init $log_level"
	echo "Running the following command:

	$command

Logs will be written to tests.log in the current working directory..."
	eval $command > tests.log 2>&1
	echo "Finished tests, opening log in Codium."
	codium tests.log

else
	command="$community_path/community_$branch/odoo-bin --addons-path="$community_path/community_$branch/addons/,$enterprise_path/enterprise_$branch/" -d $db_name --dev all $modules -p $port $test_tags $log_level $stop"
	echo $command
	eval $command
fi
