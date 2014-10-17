#!/bin/bash
set -e

function usage() {
    cat >&2 << EOF
$0

Check the blktap repository

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


[ -z "$1" ] && usage
[ -z "$2" ] && usage

set -eux

SOURCES="$1"
WORKDIR="$2"

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

. "$THISDIR/ci_lib.sh"

# check dependencies
assert_installed fakeroot
assert_installed fakechroot
assert_installed debootstrap


function install_blktap_prereqs() {
    local source_pack
    local chroot_dir
    source_pack="$1"
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_path" ]

    chroot_run "$chroot_dir" "$THISDIR/blktap_prereqs.sh"
}


function check_blktap() {
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
    tar -czf "$chroot_path/additional_files.tgz" -C "$THISDIR/blktap" ./

    chroot_run "$chroot_dir" "$THISDIR/blktap_check.sh"
}


check "$SOURCES" "$WORKDIR" \
    "install_blktap_prereqs" \
    "check_blktap"
