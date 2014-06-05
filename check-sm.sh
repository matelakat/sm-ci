#!/bin/bash
set -eux

PATH_TO_SM="$1"
WORKDIR="$2"


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
