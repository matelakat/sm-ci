#!/bin/bash
set -e

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

set -eux

PATH_TO_SM="$1"
WORKDIR="$2"

# check dependencies
assert_installed fakeroot
assert_installed fakechroot
assert_installed debootstrap

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

. "$THISDIR/ci_lib.sh"


function install_sm_prereqs() {
    local sm_tarball
    local chroot_dir
    sm_tarball="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local fakechroot_state
    local chroot_path

    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$sm_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    cp "$sm_tarball" "$chroot_path/source.tgz"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "rm -rf /storage-manager \
            && mkdir -p /storage-manager/sm \
            && cd /storage-manager/sm \
            && tar -xzf /source.tgz \
            && bash tests/install_prerequisites_for_python_unittests.sh"
}


function prepare_sm_venv() {
    local sm_tarball
    local chroot_dir
    sm_tarball="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$sm_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    cp "$sm_tarball" "$chroot_path/source.tgz"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "rm -rf /storage-manager \
            && mkdir -p /storage-manager/sm \
            && cd /storage-manager/sm \
            && tar -xzf /source.tgz \
            && bash tests/setup_env_for_python_unittests.sh"
}


function run_sm_tests() {
    local sm_tarball
    local chroot_dir
    sm_tarball="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$sm_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    cp "$sm_tarball" "$chroot_path/source.tgz"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "cd /storage-manager/sm \
            && rm -rf drivers tests \
            && tar -xzf /source.tgz \
            && bash tests/run_python_unittests.sh"
}

check "$PATH_TO_SM" "$WORKDIR" \
    "install_sm_prereqs prepare_sm_venv" \
    "run_sm_tests"
