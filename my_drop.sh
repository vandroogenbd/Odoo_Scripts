#!/bin/bash

# Path branch name
branch=$(echo $(pwd) | awk -F/ '{print $NF}' | cut -d '_' -f 2-)
# Path db name
db_name="$(echo "$branch" | awk -F'-' '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+$/) print $i}')-$(basename "$branch" | grep -oP '\d+\.\d+' | head -n 1 | tr -d '.')"

if [[ "$1" == "t" || "$1" == "test" ]]; then
	db_name="${db_name}test"
fi

rm -rf ".local/share/Odoo/filestore/$db_name"
echo "Dropped file cache"
(dropdb $db_name || true)
echo "Dropped db: $db_name"
