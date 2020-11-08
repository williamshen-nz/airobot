#!/bin/bash

set -euxo pipefail


cd $HOME

wget https://github.com/IntelRealSense/librealsense/archive/v2.39.0.tar.gz
tar -xvf v2.39.0.tar.gz && cd librealsense-2.39.0/ && mkdir build
cd build &&  cmake ../ -DFORCE_RSUSB_BACKEND=true -DBUILD_PYTHON_BINDINGS=true -DCMAKE_BUILD_TYPE=release -DBUILD_EXAMPLES=false -DBUILD_WITH_CUDA=false -DBUILD_GRAPHICAL_EXAMPLES=false
make -j && make install
cd ../.. && rm v2.39.0.tar.gz

#apt-key adv --keyserver keys.gnupg.net --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key
#add-apt-repository "deb http://realsense-hw-public.s3.amazonaws.com/Debian/apt-repo xenial main" -u
#
#apt-get update
#
#apt-get install -y \
#  librealsense2-dkms \
#  librealsense2-utils \
#  librealsense2-dev \
#  librealsense2-dbg
#
#rm -rf /var/lib/apt/lists/*
