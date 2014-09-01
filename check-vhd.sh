#!/bin/bash
set -e

function usage() {
    cat >&2 << EOF
$0

Check the vhd component within blktap repository

Usage:
    $0 SOURCES WORKSPACE

Where:
    SOURCES               A directory containing the blktap repository
                          https://github.com/xapi-project/blktap

    WORKSPACE             A workspace to be used. For the initial run, just
                          create an empty directory, and specify the same later

Example:

    git clone https://github.com/xapi-project/blktap
    git clone https://github.com/matelakat/sm-ci
    mkdir workspace
    sm-ci/check-blktap.sh blktap workspace/

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

SOURCES="$1"
WORKDIR="$2"

# check dependencies
assert_installed fakeroot
assert_installed fakechroot
assert_installed debootstrap

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

. "$THISDIR/ci_lib.sh"


function install_vhd_prereqs() {
    local source_pack
    local chroot_dir
    source_pack="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_path" ]

    chroot_run "$chroot_dir" "$THISDIR/vhd_prereqs.sh"
}


function check_vhd() {
    local source_pack
    local chroot_dir
    source_pack="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$source_pack" ]
    [ -d "$chroot_path" ]

    cp "$source_pack" "$chroot_path/source.tgz"
    cp "$THISDIR/fix_gcovr_paths.py" "$chroot_path"

    chroot_run "$chroot_dir" "$THISDIR/vhd_check.sh"
}


check "$SOURCES" "$WORKDIR" \
    "install_vhd_prereqs" \
    "check_vhd"
