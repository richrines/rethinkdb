#!/usr/bin/env bash

set -eu

pkg_dir=$(dirname $0)

conf_dir=$pkg_dir/../config

version () {
    echo $version
}

include () {
    local inc="$1"
    shift
    . "$pkg_dir/$inc" "$@"
}

# copied from the configure script
niceabspath () {
    if [[ -d "$1" ]]; then
        (cd "$1" && pwd) && return
    fi
    local dir=$(dirname "$1")
    if [[ -d "$dir" ]] && dir=$(cd "$dir" && pwd); then
        echo "$dir/$(basename "$1")" | sed 's|^//|/|'
        return
    fi
    if [[ "${1:0:1}" = / ]]; then
        echo "$1"
    else
        echo "$(pwd)/$1"
    fi
}

in_dir () {
    local dir="$1"
    shift
    ( cd "$dir" && "$@" )
}

load_pkg () {
    pkg=$1

    include "$pkg.sh"

    src_dir=$pkg_dir/../src/$pkg\_$version

    install_dir=$pkg_dir/../../build/support/$pkg\_$version
}

fetched () {
    test -e "$src_dir"
}

cmd=$1
shift

load_pkg "$1"
shift

"$cmd" "$@"
