set -eux

export HOME=/root

if ! which gdb; then
    apt-get -qy install gdb
fi

[ -n "$TEST_BASENAME" ]

TEST_FULLPATH="/additional_files/ceedling-project/build/gcov/out/${TEST_BASENAME}.out"

[ -e "$TEST_FULLPATH" ]

cd /additional_files/ceedling-project

export LD_LIBRARY_PATH=$FAKECHROOT_BASE/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
gdb $TEST_FULLPATH
