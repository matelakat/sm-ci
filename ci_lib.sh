#!/bin/bash
UBUNTU_SUITE="${UBUNTU_SUITE:-precise}"

CHROOT_SUBDIR="${UBUNTU_SUITE}-chroot"
FAKECHROOT_FNAME="fakechroot.save"


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
        if [ -e "$workdir/smroot.tgz" ]; then
            chroot_restore "$workdir/smroot.tgz" "$workdir/chroot"
        else
            chroot_create "$workdir/chroot"
            chroot_dump "$workdir/chroot" "$workdir/smroot.tgz"
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


function chroot_dump() {
    local chroot_dir
    chroot_dir="$1"

    local chroot_tarball
    chroot_tarball="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

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


function chroot_restore() {
    local chroot_tarball
    chroot_tarball="$1"

    local chroot_dir
    chroot_dir="$2"

    chroot_dir="$(readlink -f $chroot_dir)"

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


function smroot_run() {
    local chroot_dir
    chroot_dir="$1"

    local script_to_run
    script_to_run="$2"

    chroot_dir="$(readlink -f $chroot_dir)"
    script_to_run="$(readlink -f $script_to_run)"

    local fakechroot_state
    local chroot_path

    fakechroot_state="$chroot_dir/$FAKECHROOT_FNAME"
    chroot_path="$chroot_dir/$CHROOT_SUBDIR"

    [ -e "$script_to_run" ]
    [ -e "$fakechroot_state" ]
    [ -d "$chroot_path" ]

    rm "$chroot_path/the_script.sh"
    cp "$script_to_run" "$chroot_path/the_script.sh"

    fakeroot -i "$fakechroot_state" -s "$fakechroot_state" fakechroot chroot \
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


function chroot_install_sm_prereqs() {
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


function chroot_prepare_sm_venv() {
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


function chroot_run_sm_tests() {
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
