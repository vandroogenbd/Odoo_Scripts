#!/bin/bash

if [ $# -ne 2 ]
then
    echo "usage:    bash extract_db.sh  <zip_archive>         <db_name>"
    echo "example:  bash extract_db.sh  75160375-17-0-all.zip 75160375_dump"
    exit 0
fi

zipname=$(basename "$1")
customname=$2
defaultname=${zipname%.*}
dbname=${customname:-$defaultname}
mkdir -p /tmp/db-$dbname
echo "### decompressing"
rm -rf /tmp/db-$dbname
unzip -q $1 -d /tmp/db-$dbname
echo "### restoring filestore"
mkdir -p $HOME/.local/share/Odoo/filestore/$dbname
cp -rf /tmp/db-$dbname/filestore/* $HOME/.local/share/Odoo/filestore/$dbname
echo "### restoring db"
if ! createdb $dbname ; then
    echo 'Press f if you want to replace it or another key to exit'
    read -n1 REPLY
    if [[ $REPLY = "f" ]]
    then 
        dropdb $dbname && echo && echo "database removed";
        createdb $dbname
    else
        rm -rf /tmp/db-$dbname
        echo && echo exit && exit
    fi
fi
psql -q $dbname < /tmp/db-$dbname/dump.sql
# psql -d $dbname -c "update ir_cron set active='f';"
# psql -d $dbname -c "update ir_mail_server set active='f';"
# psql -d $dbname -c "UPDATE res_users SET password='admin';"
# psql -d $dbname -c "SELECT id,login FROM res_users ORDER BY id;"
# psql -d $dbname -c "update ir_config_parameter set value='2999-05-07 13:16:50' where key='database.expiration_date';"
# psql -d $dbname -c "delete from ir_config_parameter where key='database.expiration_reason'"        
# psql -d $dbname -c "UPDATE ir_config_parameter SET value = '$(cat /proc/sys/kernel/random/uuid)' WHERE key = 'database.uuid';"
echo "### cleaning"
rm -rf /tmp/db-$dbname
echo "Created db in $dbname"
