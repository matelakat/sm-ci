#!/bin/bash
UBUNTU_SUITE="${UBUNTU_SUITE:-precise}"

CHROOT_SUBDIR="${UBUNTU_SUITE}-chroot"
FAKECHROOT_FNAME="fakechroot.save"


function smroot_create() {
    local chroot_dir
    chroot_dir="$1"

    local fakechroot_state
    local chroot_path

    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_dir" ]
    [ ! -e "$fakechroot_state" ]
    [ ! -e "$chroot_path" ]

    fakeroot -s "$fakechroot_state" fakechroot debootstrap \
        --variant=fakechroot \
        --components=main,universe \
        "$UBUNTU_SUITE" \
        "$chroot_path"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "apt-get update"
}


function smroot_dump() {
    local chroot_dir
    chroot_dir="$1"

    local chroot_tarball
    chroot_tarball="$2"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ ! -e "$chroot_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "tar -czf - /" > "$chroot_tarball"
}


function smroot_restore() {
    local chroot_tarball
    chroot_tarball="$1"

    local chroot_dir
    chroot_dir="$2"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -d "$chroot_dir" ]
    [ -e "$chroot_tarball" ]
    [ ! -e "$fakechroot_state" ]
    [ ! -d "$chroot_path" ]

    fakeroot -s "$fakechroot_state" bash -c \
        "mkdir $chroot_path \
        && cd $chroot_path \
        && tar -xzf -" < "$chroot_tarball"
}


function sm_pack_create() {
    local sm_path
    sm_path="$1"

    local sm_tarball
    sm_tarball="$2"

    [ -d "$sm_path" ]
    [ ! -e "$sm_tarball" ]

    tar -czf "$sm_tarball" -C "$sm_path" ./
}


function smroot_install_prereqs() {
    local sm_tarball
    local chroot_dir
    sm_tarball="$1"
    chroot_dir="$2"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$sm_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    cp "$sm_tarball" "$chroot_path/sm.tgz"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "rm -rf /storage-manager \
            && mkdir -p /storage-manager/sm \
            && cd /storage-manager/sm \
            && tar -xzf /sm.tgz \
            && bash tests/install_prerequisites_for_python_unittests.sh"
}


function smroot_prepare_venv() {
    local sm_tarball
    local chroot_dir
    sm_tarball="$1"
    chroot_dir="$2"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$sm_tarball" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    cp "$sm_tarball" "$chroot_path/sm.tgz"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "rm -rf /storage-manager \
            && mkdir -p /storage-manager/sm \
            && cd /storage-manager/sm \
            && tar -xzf /sm.tgz \
            && bash tests/setup_env_for_python_unittests.sh"
}


function smroot_run_tests() {
    local chroot_dir
    chroot_dir="$1"

    local fakechroot_state
    local chroot_path
    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
        "$chroot_path" bash -c \
            "cd /storage-manager/sm \
            && bash tests/run_python_unittests.sh"
}
