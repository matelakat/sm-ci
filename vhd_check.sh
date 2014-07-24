set -eux
rm -rf /blktap
mkdir /blktap
cd blktap
tar -xzf /source.tgz
./autogen.sh
./configure
cd vhd
make
