#!/usr/bin/env bash

# A simple package manager for RethinkDB dependencies
#
# Each package is a shell script that defines:
#
#  install: Build and install the package into $install_dir
#           If a build step is necessary, first copy the source from $src_dir into $install_dir/build
#
#  fetch: Fetch the package source into $src_dir
#         The fetch function must fetch the source into a temporary directory
#         And then move that temporary directory to $src_dir
#
#  install-include: Copy the include files to $install_dir/include
#
#  $version: The version of the package
#
# This pkg.sh script is called by ./configure and support/build.mk
# The first argument is the function that should be called
# The second argument is usually the package to load
# This script first defines utility functions used by the packages
# Then it loads the given packge
# Then it calls the given command

set -eu

# Configure some default paths
pkg_dir=$(dirname $0)
conf_dir=$pkg_dir/../config

# These variables should be passed to this script from support/build.mk
WGET=${WGET:-}
CURL=${CURL:-}
OS=${OS:-}
COMPILER=${COMPILER:-}
CXX=${CXX:-}

# Print the version number of the package
version () {
    echo $version
}

# Include a file local to $pkg_dir
include () {
    local inc="$1"
    shift
    . "$pkg_dir/$inc" "$@"
}

# Utility function copied from the configure script
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

# in_dir <dir> <cmd> <args...>
# Run the command in dir
in_dir () {
    local dir="$1"
    shift
    ( cd "$dir" && "$@" )
}

# Load a package and set related variables
load_pkg () {
    pkg=$1
    include "$pkg.sh"
    src_dir=$pkg_dir/../src/$pkg\_$version
    install_dir=$pkg_dir/../../build/support/$pkg\_$version
}

# Test if the package has already been fetched
fetched () {
    test -e "$src_dir"
}

# Make a shallow clone of a specific git tag
git_clone_tag () {
    local remote tag repo
    remote=$1
    tag=$2
    repo=$3
    ( cd "$repo"
      git init
      git remote add origin "$remote"
      git fetch --depth 1 origin "$tag"
      git checkout FETCH_HEAD
      rm -rf .git
    )
}

# Download a file to stdout
geturl () {
    if [[ -n "${WGET:-}" ]]; then
        $WGET --quiet --output-document=- "$@"
    else
        ${CURL:-curl} --silent "$@"
    fi
}

# Read the command
cmd=$1
shift

# Load the package
load_pkg "$1"
shift

# Run the command
"$cmd" "$@"
