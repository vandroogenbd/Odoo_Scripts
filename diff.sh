#!/bin/bash

# usage: diff <number_of_commits>

if [ $# -ge 2 ]
then
	echo "usage: diff <number_of_commits>"
	exit 0
fi

git diff HEAD~$1
