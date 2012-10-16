#!/bin/bash

DIR=`dirname $0`

copy() {
    from="$1"
    if [ -z "$2" ]; then
        to="$1"
    else
        to="$2"
    fi

    rm -rf "$HOME/$to"
    cp -frv "$from" "$HOME/$to"
}

symlink() {
    from="$1"
    if [ -z "$2" ]; then
        to="$1"
    else
        to="$2"
    fi

    rm "$HOME/$to"
    ln -Fsv "$from" "$HOME/$to"
}

loadconf() {
    REPO="$DIR/$1"
    source "$REPO/config.sh"
}

source_config() {
    if [ -f "$DIR/config-local.sh" ]; then
        source "$DIR/config-local.sh"
    else
        source "$DIR/config.sh"
    fi
}

dotfiles_init() {
    pushd $DIR > /dev/null
    git submodule update --recursive --init
    git submodule foreach --recursive git checkout master
    popd > /dev/null
    source_config
}

dotfiles_update() {
    pushd $DIR > /dev/null
    output=`git submodule foreach --recursive git pull origin master 2>&1 | \
        grep -v '^From' | grep -v "FETCH_HEAD" | grep -v '^Entering' | \
        grep -v "up-to-date\.$"`
    if [ -n "$output" ]; then
        echo "$output";
        git submodule foreach --recursive git checkout master 2>&1 > /dev/null
        popd > /dev/null
        source_config
    else
        echo "Everything up-to-date."
    fi
}

dotfiles_push() {
    pushd $DIR > /dev/null
    git commit -a -m 'Submodules update'
    git push
    popd $DIR > /dev/null
}

case $1 in
init|--init)
    dotfiles_init
    ;;
update|--update)
    dotfiles_update
    ;;
push|--push)
    dotfiles_push
    ;;
*)
    echo "Usage: $0 <init|update>" >&2
    ;;
esac



