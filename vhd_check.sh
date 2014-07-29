set -eux
rm -rf /blktap
mkdir /blktap
cd blktap
tar -xzf /source.tgz
./autogen.sh
export CFLAGS="-fprofile-arcs -ftest-coverage -g"
export CPPLAGS="-fprofile-arcs -ftest-coverage -g"
./configure
cd vhd
make
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./lib/.libs ./vhd-util
gcovr -x -f "/blktap/.*" | sed -e 's,/blktap/,blktap/,g' > /blktap/coverage.xml
