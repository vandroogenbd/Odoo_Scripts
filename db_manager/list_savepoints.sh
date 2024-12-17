#!/bin/bash
# List all savepoints for the currently set_db

# Retrieve the database name
db_name=$(PATH_TO_ODOO_SCRIPTS_FOLDER/db_manager/getdb)

# Get list of matching savepoints from PostgreSQL
savepoints=$(psql -U odoo -t -c "SELECT datname FROM pg_database;" | grep "$db_name"_)

# Output the result
echo "Savepoints for $db_name:"
echo "$savepoints"
