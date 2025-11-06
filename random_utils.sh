# --- Random utils

# Kill specific port process
kp() {
    kill $(lsof -t -i:$1)
}

# Fetch and switch to branch
gsw() {
    local remote=${1:-origin}
    local branch=$2

    # If only one argument is provided, treat it as the branch
    if [ -z "$branch" ]; then
        branch=$1
        remote="origin"
    fi

    git fetch $remote $branch
    git switch $branch
    git pull
}

venv() {
    if [[ "$(which python)" == "/home/odoo/venv/bin/python" ]]; then
        deactivate
    else
        source $HOME/venv/bin/activate
    fi
}
