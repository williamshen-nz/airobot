#!/bin/bash
set -e

# setup ros environment
source "/root/catkin_ws/devel/setup.bash"

pip install -e /root/improbable/airobot

eval "bash"

exec "$@"
