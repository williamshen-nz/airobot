# syntax=docker/dockerfile:experimental

### first stage ###
# Building from nvidia-opengl for visualization capability
FROM ubuntu:xenial as intermediate

RUN  apt-get -yq update && \
     apt-get -yqq install ssh git \
     && rm -rf /var/lib/apt/lists/*

RUN mkdir /root/tmp_code
RUN mkdir /root/tmp_thirdparty

WORKDIR /root/tmp_code

RUN mkdir /root/.ssh/

# make sure your domain is accepted
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# clone private repo - airobot
RUN --mount=type=ssh git clone git@github.com:Improbable-AI/ur5e.git
RUN --mount=type=ssh git clone git@github.com:Improbable-AI/camera_calibration.git
WORKDIR /root/tmp_code/ur5e

# update submodules (ur_modern_driver, industrial_msgs, and gazebo plugin for gripper)
RUN --mount=type=ssh git submodule update --init

### second stage ###
FROM nvidia/cudagl:11.1-runtime-ubuntu20.04

# setup timezone
RUN echo 'America/New_York' > /etc/timezone && \
    ln -s /usr/share/zoneinfo/America/New_York /etc/localtime && \
    apt-get update && \
    apt-get install -q -y --no-install-recommends tzdata && \
    rm -rf /var/lib/apt/lists/*

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Replacing shell with bash for later docker build commands
RUN mv /bin/sh /bin/sh-old && \
  ln -s /bin/bash /bin/sh

# install basic system stuff
COPY ./install_scripts/install_basic.sh /tmp/install_basic.sh
RUN chmod +x /tmp/install_basic.sh && /tmp/install_basic.sh

COPY ./install_scripts/install_python3_8.sh /tmp/install_python3_8.sh
RUN chmod +x /tmp/install_python3_8.sh && /tmp/install_python3_8.sh

# install ROS stuff
ENV ROS_DISTRO noetic

COPY install_scripts/install_ros_noetic.sh /tmp/install_ros_noetic.sh
RUN chmod +x /tmp/install_ros_noetic.sh && /tmp/install_ros_noetic.sh


# create catkin workspace
ENV CATKIN_WS /root/catkin_ws
RUN source /opt/ros/$ROS_DISTRO/setup.bash && mkdir -p $CATKIN_WS/src
WORKDIR ${CATKIN_WS}
RUN catkin init && catkin config --extend /opt/ros/$ROS_DISTRO \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DCATKIN_ENABLE_TESTING=False
WORKDIR $CATKIN_WS/src

# install realsense camera deps
COPY install_scripts/install_realsense_src.sh /tmp/install_realsense_src.sh
RUN chmod +x /tmp/install_realsense_src.sh && /tmp/install_realsense_src.sh

# clone repositories into workspace and build
WORKDIR ${CATKIN_WS}/src

RUN git clone https://github.com/IntelRealSense/realsense-ros.git && \
    cd realsense-ros/ && \
    git checkout `git tag | sort -V | grep -P "^2.\d+\.\d+" | tail -1` && \
    cd .. && \
    git clone https://github.com/Improbable-AI/aruco_ros.git && \
    git clone https://github.com/pal-robotics/ddynamic_reconfigure.git && \
    git clone https://github.com/lagadic/vision_visp.git && \
    cd vision_visp && rm -rf visp_auto_tracker && \
    cd ..


# copy over ur5e repositoriy from cloning private repo
COPY --from=intermediate /root/tmp_code ${CATKIN_WS}/src/

# install visp (only required if you need to do camera hand-eye calibration
COPY install_scripts/install_visp.sh /tmp/install_visp.sh
RUN chmod +x /tmp/install_visp.sh && /tmp/install_visp.sh
# build
ENV VISP_DIR /root/visp-ws/visp-build

## currently (11/08/2020), industrial_trajectory_filters still fails to compile for ROS noetic
RUN cd ur5e/industrial_core && rm -rf industrial_trajectory_filters
WORKDIR ${CATKIN_WS}
RUN catkin build

# install pytorch and cuDNN
ENV CUDNN_VERSION 8.0.4.30
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

COPY ./install_scripts/install_pytorch_cudnn8.sh /tmp/install_pytorch_cudnn8.sh
RUN chmod +x /tmp/install_pytorch_cudnn8.sh && /tmp/install_pytorch_cudnn8.sh

ENV IMPROB /root/improbable
RUN mkdir ${IMPROB}

# copy local requirements file for pip install python deps
COPY ./requirements.txt ${IMPROB}
WORKDIR ${IMPROB}
RUN pip install -r requirements.txt && rm requirements.txt

RUN echo "source /root/catkin_ws/devel/setup.bash" >> /root/.bashrc
WORKDIR /

# Exposing the ports
EXPOSE 11311

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES \
  ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
  ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

# setup entrypoint
COPY ./entrypoint.sh /

ENTRYPOINT ["./entrypoint.sh"]
CMD ["bash"]
