#!/bin/bash
set -eux

function usage() {
    cat >&2 << EOF
$0

Check a given sm repository

Usage:
    $0 SM_SOURCES WORKSPACE

Where:
    SM_SOURCES            A directory containing the storage manager repository
                          https://github.com/xapi-project/sm

    WORKSPACE             A workspace to be used. For the initial run, just
                          create an empty directory, and specify the same later

Example:

    git clone https://github.com/xapi-project/sm
    git clone https://github.com/matelakat/sm-ci
    mkdir workspace
    sm-ci/check-sm.sh sm workspace/

EOF
    exit 1
}


function assert_installed() {
    if which $1; then
        return
    fi
    cat >&2 << EOF
Error:

$1 was not found, please install it to your system.
EOF
    exit 1
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

PATH_TO_SM="$1"
WORKDIR="$2"

# check dependencies
assert_installed fakeroot
assert_installed fakechroot
assert_installed debootstrap

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

. "$THISDIR/ci_lib.sh"

check "$PATH_TO_SM" "$WORKDIR" \
    "chroot_install_sm_prereqs chroot_prepare_sm_venv"
