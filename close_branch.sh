#!/bin/bash

# usage: close_branch

# Default root path
root_path="~/work"

# community master repo
community_master_path=~/work/community-master
# enterprise master repo
enterprise_master_path=~/work/enterprise-master

# Branch name
branch_name=""

if [ $# -ne 1 ]
then
	echo -e "Expected folder architecture:
~
└── work
    ├── community_master
    ├── enterprise_master
    ├── community_branch_to_close
    └── enterprise_branch_to_close

Usage:	 bash close_branch.sh <branch_name>
Example: bash close_branch.sh 18.0-opw-420_my_old_branch-quad
\033[0;31m
/!\\ Use with caution as this is irreversible /!\\"
	exit 0
fi

branch_name=$1
db_name=$(echo $1 | awk -F'-' '{split($1,v,"."); print $3 "-" v[1] v[2] }')

read -p "Remove branch '$branch_name'? " -n 1 -r
echo ""
if [[ $REPLY = "" ]];
then
	PATH_TO_ODOO_SCRIPTS_FOLDER/db_manager/dropall $db_name
	echo "
Dropped dbs!"

	cd $community_master_path
	git worktree remove ../community_$branch_name --force
	git branch | grep $branch_name | xargs git branch -D

	cd $enterprise_master_path
	git worktree remove ../enterprise_$branch_name --force
	git branch | grep $branch_name | xargs git branch -D

    echo "
Finished cleanup!"
fi
