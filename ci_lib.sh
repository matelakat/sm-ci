#!/bin/bash
UBUNTU_SUITE="${UBUNTU_SUITE:-precise}"

CHROOT_SUBDIR="${UBUNTU_SUITE}-chroot"
UBUNTU_MIRROR="http://www.mirrorservice.org/sites/archive.ubuntu.com/ubuntu/"


function check() {
    local sources
    local workdir
    local prepare_functions
    local test_functions

    sources="$1"
    workdir="$2"
    prepare_functions="$3"
    test_functions="$4"

    sources=$(readlink -f $sources)
    workdir=$(readlink -f $workdir)

    [ -d "$workdir" ]
    [ -d "$sources" ]

    rm -f "$workdir/source.tgz"
    source_pack_create "$sources" "$workdir/source.tgz"

    [ -d "$workdir/chroot" ] || {
        mkdir "$workdir/chroot"
        if [ -e "$workdir/chroot.tgz" ]; then
            chroot_restore "$workdir/chroot.tgz" "$workdir/chroot"
        else
            chroot_create "$workdir/chroot"
            chroot_dump "$workdir/chroot" "$workdir/chroot.tgz"
        fi

        for prepare_function in $prepare_functions; do
            $prepare_function "$workdir/source.tgz" "$workdir/chroot"
        done
    }

    for test_function in $test_functions; do
       $test_function "$workdir/source.tgz" "$workdir/chroot"
    done
}


function chroot_create() {
    local chroot_dir
    chroot_dir="$1"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path

    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_dir" ]
    [ ! -e "$chroot_path" ]

    $(fakechroot_call) fakeroot debootstrap \
        --components=main,universe \
        "$UBUNTU_SUITE" \
        "$chroot_path" \
        "$UBUNTU_MIRROR"

    $(fakechroot_call) fakeroot chroot \
        "$chroot_path" bash -c \
            "apt-get update"
}


function chroot_dump() {
    local chroot_dir
    chroot_dir="$1"

    local chroot_tarball
    chroot_tarball="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path

    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ ! -e "$chroot_tarball" ]
    [ -d "$chroot_path" ]

    $(fakechroot_call) fakeroot chroot \
        "$chroot_path" bash -c \
            "tar -czf - --exclude=sys --exclude=proc --exclude=dev/* /" > "$chroot_tarball"
}


function chroot_restore() {
    local chroot_tarball
    chroot_tarball="$1"

    local chroot_dir
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

    local chroot_path

    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_dir" ]
    [ -e "$chroot_tarball" ]
    [ ! -d "$chroot_path" ]

    fakeroot bash -c \
        "mkdir $chroot_path \
        && cd $chroot_path \
        && tar -xzf -" < "$chroot_tarball"
}


function chroot_run() {
    local chroot_dir
    chroot_dir="$1"

    local script_to_run
    script_to_run="$2"

    chroot_dir="$(readlink -f $chroot_dir)"
    script_to_run="$(readlink -f $script_to_run)"

    local chroot_path

    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$script_to_run" ]
    [ -d "$chroot_path" ]

    rm -f "$chroot_path/the_script.sh"
    cp "$script_to_run" "$chroot_path/the_script.sh"

    $(fakechroot_call) fakeroot chroot \
        "$chroot_path" bash /the_script.sh
}


function source_pack_create() {
    local source_path
    source_path="$1"

    local source_tarball
    source_tarball="$2"

    [ -d "$source_path" ]
    [ ! -e "$source_tarball" ]

    tar -czf "$source_tarball" -C "$source_path" ./
}


function fakechroot_call() {
    echo "fakechroot -e debootstrap"
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
