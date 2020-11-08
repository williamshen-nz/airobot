#!/bin/bash

set -euxo pipefail

echo "export VISP_WS=$HOME/visp-ws" >> ~/.bashrc
export VISP_WS=$HOME/visp-ws
mkdir -p $VISP_WS
cd $VISP_WS
git clone https://github.com/lagadic/visp.git
mkdir -p $VISP_WS/visp-build
cd $VISP_WS/visp-build
cmake ../visp
make -j
echo "export VISP_DIR=$VISP_WS/visp-build" >> ~/.bashrc
#source ~/.bashrc

