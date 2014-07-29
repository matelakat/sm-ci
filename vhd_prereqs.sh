set -eux
apt-get -qy install autoconf libtool libaio-dev uuid-dev make libxen-dev \
    python-pip

pip install gcovr

