#!/bin/bash
set -e

function usage() {
    cat >&2 << EOF
$0

Debug a test binary

Usage:
    $0 WORKSPACE TEST_BASENAME

Where:
    WORKSPACE             A workspace to be used.

    TEST_BASENAME         The basename of the test file you whish to debug.

Example:

To debug the test represented by `test_td-ctx.c`, do the following:

    sm-ci/debug-blktap.sh workspace/ test_td-ctx

EOF
    exit 1
}


[ -z "$1" ] && usage
[ -z "$2" ] && usage

set -eux

WORKDIR="$1"
TEST_BASENAME="$2"

THISFILE=$(readlink -f $0)
THISDIR=$(dirname $THISFILE)

. "$THISDIR/ci_lib.sh"

# check dependencies
assert_installed fakeroot
assert_installed fakechroot


function debug_blktap() {
    local chroot_dir
    local test_basename
    chroot_dir="$1"
    test_basename="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_path" ]

    TEST_BASENAME=$test_basename chroot_run "$chroot_dir" "$THISDIR/blktap_debug.sh"
}


debug_blktap "$WORKDIR/chroot" "$TEST_BASENAME"
