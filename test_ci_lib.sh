#!/bin/bash
set -eux

. ci_lib.sh


workdir=$(mktemp -d)
mkdir "$workdir/smroot"

chroot_create "$workdir/smroot"
smroot_dump "$workdir/smroot" "$workdir/smroot.tgz"
rm -rf "$workdir/smroot"
mkdir "$workdir/smroot"
chroot_restore "$workdir/smroot.tgz" "$workdir/smroot"
rm -rf "$workdir"
