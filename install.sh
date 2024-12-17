#!/bin/bash

dest="$HOME/.odoo_scripts"

# Ask for destination
read -r -p "Enter destination folder (default: $dest): " user_dest
if [ -n "$user_dest" ]; then
    eval dest=$user_dest
    if [[ ! "$dest" == "$HOME"* ]]; then
    	dest="$HOME/$dest"
    fi
fi
echo $dest

# Create destination folder & copy content
mkdir -p $dest
shopt -s dotglob
cp -r ./* $dest
shopt -u dotglob

# Edit scripts with correct location
find $dest -type f -exec sed -i "s#PATH_TO_ODOO_SCRIPTS_FOLDER#$dest#g" {} +

# Add aliases to ~/.bash_aliases
cat "$dest/bash_install/header" "$dest/bash_install/odoo_scripts.aliases" "$dest/bash_install/utils" "$dest/bash_install/db_utils.aliases" "$dest/bash_install/git.aliases" "$dest/bash_install/footer" >> $HOME/.bashrc

# Set up worktree, either from existing folder or new clone & set playground up

# TODO
