#!/bin/bash

# usage: new_branch <origin_branch> <version>


# community master repo
community_master_path=~/work/community-master
# enterprise master repo
enterprise_master_path=~/work/enterprise-master


# Branch name
destination_branch=""
# Odoo version
version=-1

if [ $# -ne 2 ]
then
	echo "usage:   	bash new_branch.sh	<destination_branch>	<version>"
	echo "example: 	bash new_branch.sh 	420-fix_a_new_bug	saas-17.2"
	exit 0
fi

destination_branch=$2-opw-$1-drod
version=$2

read -p "Continue with branch name: '$destination_branch' & version: '$version' ? " -n 1 -r
echo ""
if [[ $REPLY = "" ]];
then
    cd $community_master_path
	git fetch
	git pull
	git worktree add -b $destination_branch ../community_$destination_branch origin/$version

	cd $enterprise_master_path
	git fetch
	git pull
	git worktree add -b $destination_branch ../enterprise_$destination_branch origin/$version

	# Created destinations
	dst_community=~/work/community_$destination_branch
	dst_enterprise=~/work/enterprise_$destination_branch

	# Add commit messages
	cp ~/commit_template.txt "$dst_community/commit.message"
	cp ~/commit_template.txt "$dst_enterprise/commit.message"

	# Add VSCode workspace settings
	version_number=$(basename "$2" | grep -oP '\d+\.\d+')
	db_name="$(echo "$1" | cut -d'-' -f1)-$version_number"
	loc=$dst_community/$(echo $destination_branch | cut -d '-' -f 3-4).code-workspace
	cp ~/scripts/templates/workspace.json $loc

	sed -i "s|COMMUNITY_PATH|$dst_community|g" $loc
	sed -i "s|ENTERPRISE_PATH|$dst_enterprise|g" $loc
	sed -i "s|BRANCH|$destination_branch|g" $loc
	sed -i "s|XX.X|$version_number|g" $loc
	sed -i "s|DB_NAME|$db_name|g" $loc

	codium -n $loc
fi
