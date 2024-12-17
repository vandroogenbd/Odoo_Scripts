# Transform number into odoo version branch
odoo_version() {
    local arg="$1"
    if [[ "$arg" == "master" ]]; then
        echo "$arg"
    elif [[ "${arg: -1}" == "0" ]]; then
        echo "${arg:0:${#arg}-1}.${arg: -1}"
    else
        echo "saas-${arg:0:${#arg}-1}.${arg: -1}"
    fi
}

# Update version in workspace
update_workspace() {
    local current_branch="$1"
    local new_version="$2"
    cd ~/playground
    if [[ "$current_branch" == "saas-"* ]]; then
        current_branch="${current_branch/saas-}"
    fi

    sed -i "s|${current_branch/.}|$new_version|g" playground.code-workspace
}

# Switch playground version
psw() {
    if [ $# -lt 1 ]; then
        echo "usage: psw <version>"
        exit 0
    fi
    curr_dir=$(pwd)
    branch=$(odoo_version "$1")

    cd ~/playground/community
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "$branch" ]; then
        git fetch origin $branch > /dev/null 2>&1
        git switch -f $branch > /dev/null 2>&1
        git pull -f > /dev/null 2>&1
        git clean -fd > /dev/null 2>&1
        echo "Switched community to $branch"
    fi

    if [ "$current_branch" != "$branch" ]; then
        update_workspace $current_branch $1
    fi

    cd ~/playground/enterprise
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "$branch" ]; then
        git fetch origin $branch > /dev/null 2>&1
        git switch -f $branch > /dev/null 2>&1
        git pull -f > /dev/null 2>&1
        git clean -fd > /dev/null 2>&1
        echo "Switched enterprise to $branch"
    fi

    cd $curr_dir
}

# Open codium for specific version
check() {
    if [ $# -lt 1 ]; then
        echo "usage: check <version>"
        exit 0
    fi
    psw $1
    codium -n ~/playground/playground.code-workspace
}

# Run a specific (playground) version of Odoo
# First arg is the version, order of the rest doesn't matter
# -r drops the target db before running Odoo, it is not passed to the Odoo CLI
# Ex: ro 180 --test-tags=.test1 -r -i sale
#   -> drops db 180 before running Odoo 18.0 (with db name being 180)
ro() {
    if [[ -z "${1-}" || "$1" == "-h" ]]; then
        echo -e "Run a specific version of Odoo
First arg is the version, order of the rest doesn't matter
-r drops the target db before running Odoo, it is not passed to the Odoo CLI
Ex: ro 180 --test-tags=.test1 -r -i sale
    -> drops db 180 before running Odoo 18.0 (with db name being 180)
Ex: ro 180 shell 42069-180
    -> runs an odoo-shell using the DB for ticket 42069"
        return
    fi
    # Console Mode
    console_mode=false
    version="$1"
    shift
    args=()

    # Collect arguments, detect -r, and ignore it from args
    for arg in "$@"; do
        if [[ "$arg" == "-r" ]]; then
            dropdb "$version-clean" > /dev/null 2>&1
            echo "Dropped db $version-clean"
        elif [[ "$arg" == "shell" ]]; then
            console_mode=true
        else
            args+=("$arg")
        fi
    done

    psw $version
    if $console_mode; then
        ~/playground/community/odoo-bin shell --addons-path=~/playground/community/addons/,~/playground/enterprise/ -d "$version-clean" ${args[*]}
    else
        ~/playground/community/odoo-bin --addons-path=~/playground/community/addons/,~/playground/enterprise/ -d "$version-clean" ${args[*]}
    fi
}

# Drop playground db of current version
dropc() {
    current_dir=$(pwd)
    cd ~/playground/community
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Convert branch name to db version format
    if [[ "$current_branch" == "master" ]]; then
        db_name="master-clean"
    elif [[ "$current_branch" == saas-* ]]; then
        version="${current_branch#saas-}"
        db_name="${version//./}-clean"
    else
        db_name="${current_branch//./0}-clean"   # 18.0 -> 180
    fi

    dropdb "$db_name" || echo "DB $db_name doesn't exist"
    cd "$current_dir"
}
