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
    if which $0; then
        return
    fi
    cat >&2 << EOF
Error:

$0 was not found, please install it to your system.
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

PATH_TO_SM=$(readlink -f $PATH_TO_SM)
WORKDIR=$(readlink -f $WORKDIR)


. "$THISDIR/sm_ci_lib.sh"

[ -d "$WORKDIR" ]

rm -f "$WORKDIR/sm.tgz"
sm_pack_create "$PATH_TO_SM" "$WORKDIR/sm.tgz"

[ -d "$WORKDIR/smroot" ] || {
    mkdir "$WORKDIR/smroot"
    if [ -e "$WORKDIR/smroot.tgz" ]; then
        smroot_restore "$WORKDIR/smroot.tgz" "$WORKDIR/smroot"
    else
        smroot_create "$WORKDIR/smroot"
        smroot_dump "$WORKDIR/smroot" "$WORKDIR/smroot.tgz"
    fi
    smroot_install_prereqs "$WORKDIR/sm.tgz" "$WORKDIR/smroot"
    smroot_prepare_venv "$WORKDIR/sm.tgz" "$WORKDIR/smroot"
}

smroot_run_tests "$WORKDIR/sm.tgz" "$WORKDIR/smroot"
