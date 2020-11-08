#!/bin/bash

set -euxo pipefail

# install pytorch
pip install torch==1.7.0+cu110 torchvision==0.8.1+cu110 -f https://download.pytorch.org/whl/torch_stable.html


