#!/bin/bash

DIR=`dirname $PWD/$0`

WINDOWS() {
    uname -s | egrep -iq '(Cygwin|MinGW)'
}

MACOS() {
    [ $(uname -s) = 'Darwin' ]
}

LINUX() {
    [ $(uname -s) = 'Linux' ]
}

fetch_repo() {
    pushd $DIR > /dev/null

    loc=$1
    remote=$(grep " $loc$" repos.conf | awk '{ print $1 }')

    cd repos

    if [ ! -e $loc ]; then
        echo "Cloning $remote into $loc..." >&2
        git clone --recursive --quiet "$remote" "$loc"
    fi

    popd > /dev/null
}

require() {
    repo=$1

    if [ -d $DIR/repos/$repo ]; then
        echo "Skipping $1..." >&2
        return
    fi

    fetch_repo $repo

    echo "Setting up $1..." >&2

    pushd $DIR/repos > /dev/null

    cd $repo

    if [ ! -f dotfiles_config.sh ]; then
        echo -n "No dotfiles_config.sh found for repo $repo, " >&2
        echo "linking to ~/.$repo" >&2

        if [ ! -e "$HOME/.$repo" ]; then
            ln -sv "$PWD" "$HOME/.$repo"
        else
            echo "$HOME/.$repo: File exists" >&2
        fi
    else 
        source dotfiles_config.sh

        for file in ${INCLUDE[*]}; do
            src=$(awk -F: '{ print $1 }' <<< $file)
            tgt=$(awk -F: '{ print $2 }' <<< $file)

            if [ -z "$tgt" ]; then
                tgt="$src"
            fi

            # TODO: Copy on windows?
            if [ ! -e "$HOME/$tgt" ]; then
                ln -sv "$PWD/$src" "$HOME/$tgt"
            else
                echo "$HOME/$tgt: File exists" >&2
            fi
        done
    fi

    popd > /dev/null
}

save_last_update() {
    date '+%s' > "$DIR/.last_update"
}

all_repos() {
    pushd $DIR > /dev/null

    repos=$(cat repos.conf)

    local IFS=$'\n'
    for repo in $repos; do
        awk '{ print $2 }' <<< $repo
    done

    popd > /dev/null
}

dotfiles_install() {
    mkdir -p $DIR/repos

    pushd $DIR/repos > /dev/null

    repos="$@"

    if [ -z "$@" ]; then
        repos=$(all_repos)
    fi

    for repo in $repos; do
        require $repo
    done

    popd > /dev/null

    save_last_update
}

case $1 in
install|--install)
    shift
    dotfiles_install "$@"
    ;;
status|--status)
    shift
    # TODO
    ;;
update|--update)
    shift
    # TODO
    ;;
*)
    echo "Usage: $0 install [...]" >&2
    ;;
esac



