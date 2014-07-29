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
