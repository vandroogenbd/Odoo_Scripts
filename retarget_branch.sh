#!/bin/bash

# community master repo
community_master_path=~/work/community-master

# calling directory
curr_dir=$(pwd)
# community path for current branch
community_path="${curr_dir/enterprise/community}"
# enterprise path for current branch
enterprise_path="${curr_dir/community/enterprise}"

# Target name on origin
target_branch=""
# Number of commits to cherry-pick on new target
num_community_commits=-1
num_enterprise_commits=-1

if [ $# -ne 3 ]
then
	echo "usage:   	bash retarget_branch.sh		<target_branch>		<#community_commits>	<#enterprise_commits>"
	echo "example: 	bash retarget_branch.sh 	saas-17.4      		2                   	0"
	exit 0
fi

target_branch=$1

# Verify target is legit
cd $community_master_path
existing_versions=$(git ls-remote --heads origin | awk -F'/' '{print $NF}')
if ! echo "$existing_versions" | grep -q "^$target_branch$"; then
    echo "Error: '$target_branch' is not a valid target!"
    exit 1
fi

num_community_commits=$2
community_commit_hashes=""
num_enterprise_commits=$3
enterprise_commit_hashes=""

echo "$num_commits"
if [ $num_community_commits -gt 0 ]; then
	cd $community_path
	community_commit_hashes=( $(git log -n "$num_community_commits" --format="%H") )
	echo -e "\e[1mCommunity commits to cherry-pick:\e[0m\n"
	git log --pretty=format:"%C(yellow)%<(12)%h%Creset | %Cblue%<(30)%an%Creset | %Cgreen%s%Creset" -$num_community_commits
fi

if [ $num_enterprise_commits -gt 0 ]; then
	cd $enterprise_path
	enterprise_commit_hashes=( $(git log -n "$num_community_commits" --format="%H") )
	echo -e "\e[1mEnterprise commits to cherry-pick:\e[0m\n"
	git log --pretty=format:"%C(yellow)%<(12)%h%Creset | %Cblue%<(30)%an%Creset | %Cgreen%s%Creset" -$num_enterprise_commits
fi

echo ""
if (( num_community_commits + num_enterprise_commits > 2 )); then
	echo -e "\033[0;31mCherry-picking many commits.\e[0m"
fi
read -p "Continue? " -n 1 -r
echo ""
if [[ $REPLY = "" ]]; then
	cd $community_path
	echo "
Retargetting community branch
"
	git branch --set-upstream-to=origin/$target_branch
	git reset --hard origin/$target_branch
	echo "Cherrypicking community commits"
	for (( idx=${#community_commit_hashes[@]} - 1; idx >= 0; idx-- )); do
	    git cherry-pick ${community_commit_hashes[idx]}
	done
	echo -e "\033[0;32m
Community done
\e[0m"
	cd $enterprise_path
	echo "
Retargetting enterprise branch
"
	git branch --set-upstream-to=origin/$target_branch
	git reset --hard origin/$target_branch
	echo "Cherrypicking enterprise commits"
	for (( idx=${#enterprise_commit_hashes[@]} - 1; idx >= 0; idx-- )); do
	    git cherry-pick ${enterprise_commit_hashes[idx]}
	done
	echo -e "\033[0;32m
Enterprise done
\e[0m"
	cd $curr_dir
	echo -e "\nRetargeting done!"
fi
