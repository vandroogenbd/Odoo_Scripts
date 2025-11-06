#!/bin/bash

# community master repo
community_master_path=$HOME/work/community-master

# calling directory
curr_dir=$(pwd)
# community path for current branch
community_path="${curr_dir/enterprise/community}"
# enterprise path for current branch
enterprise_path="${curr_dir/community/enterprise}"

if [ $# -ne 1 ]
then
	echo "usage:   	bash forward.sh	   <forward_branch>"
	echo "example: 	bash forward.sh    saas-18.4"
	exit 0
fi


# Input verification
target_branch=$1
# Verify target branch exists
cd $community_master_path
existing_versions=$(git ls-remote --heads origin | awk -F'/' '{print $NF}')
if ! echo "$existing_versions" | grep -q "^$target_branch$"; then
    echo -e "\e[31mError: '$target_branch' is not a valid target!\e[0m"
    exit 1
fi
# Verify target branch is a different version
cd $curr_dir
current_version=$( git rev-parse --abbrev-ref --symbolic-full-name @{u} | sed 's/^\(dev\|origin\)\///' )
if [[ "$current_version" == "$target_branch"* ]]; then
    echo -e "\e[31mError: current version is already '$target_branch'!\e[0m"
    exit 1
fi


# Community side
cd $community_path
fw_branch=false
current_branch=$(git branch --show-current)
# Check whether current branch is already a FW
if [[ "$current_branch" == *"-fw" ]]; then
	# Remove anything after the first decimal number, reverse string, remove anything before the second "-", reverse again.
	# This gives the original branch name (before the previous FW).
	# eg. saas-18.2-18.0-opw-4865082-reference_all_split_mo_in_picking-drod-457866-fw => 18.0-opw-4865082-reference_all_split_mo_in_picking-drod
	current_branch=$( echo $current_branch | sed -E 's/^[^-]*-([0-9]+(\.[0-9]+)?)-(.*)/\3/' | rev | cut -d'-' -f3- | rev )
fi
# Find the FW branch on the remote
fw_branch=$(git branch -r | grep "$target_branch-$current_branch" | sed 's/^[[:space:]]*//' | sed 's|dev/||')
if [ $fw_branch ]; then
	git fetch dev $fw_branch > /dev/null
	git switch $fw_branch > /dev/null
else
	echo -e "\e[31mCould not find a community FW!\e[0m"
	echo "Defaulting to: $target_branch"
	echo ""
	fw_branch=$target_branch
	git switch $fw_branch > /dev/null
	git pull > /dev/null
fi
echo ""
echo -e "\e[32mCommunity done!\e[0m"
echo "Switched to: $fw_branch"
echo ""


# Enterprise side
cd $enterprise_path
fw_branch=false
current_branch=$(git branch --show-current)
# Check whether current branch is already a FW
if [[ "$current_branch" == *"-fw" ]]; then
	current_branch=$( echo $current_branch | sed -E 's/^[^-]*-([0-9]+(\.[0-9]+)?)-(.*)/\3/' | rev | cut -d'-' -f3- | rev )
fi
# Find the FW branch on the remote
fw_branch=$(git branch -r | grep "$target_branch-$current_branch" | sed 's/^[[:space:]]*//' | sed 's|dev/||')
if [ $fw_branch ]; then
	git fetch dev $fw_branch > /dev/null
	git switch $fw_branch > /dev/null
else
	echo -e "\e[31mCould not find an enterprise FW!\e[0m"
	echo "Defaulting to: $target_branch"
	echo ""
	fw_branch=$target_branch
	git switch $fw_branch > /dev/null
	git pull > /dev/null
fi
echo ""
echo -e "\e[32mEnterprise done!\e[0m"
echo "Switched to: $fw_branch"
echo ""


# Update workspace configuration
cd $community_path
db_name_current=$(echo ${current_branch#saas-} | cut -d'-' -f1 | tr -d '.')
db_name_new=$(echo ${target_branch#saas-} | tr -d '.')
loc=$community_path/$(echo ${community_path#*opw-} | rev | cut -d'-' -f2- | rev).code-workspace
sed -i "s|$db_name_current|$db_name_new|g" $loc


# All done
cd $curr_dir
echo -e "\e[32mDone!\e[0m"
exit 0
