import matplotlib.pyplot as plt
import numpy as np

from airobot import Robot


def main():
    """
    This function demonstrates how to setup camera
    and get rgb/depth images.
    """
    robot = Robot('ur5e', arm_cfg={'render': True})
    focus_pt = [0, 0, 1]  # ([x, y, z])
    robot.cam.setup_camera(focus_pt=focus_pt,
                           dist=3,
                           yaw=0,
                           pitch=0,
                           roll=0)
    robot.arm.go_home()
    rgb, depth = robot.cam.get_images(get_rgb=True,
                                      get_depth=True)
    plt.figure()
    plt.imshow(rgb)
    plt.figure()
    plt.imshow(depth * 25, cmap='gray', vmin=0, vmax=255)
    print('Maximum Depth (m): %f' % np.max(depth))
    print('Minimum Depth (m): %f' % np.min(depth))
    plt.show()


if __name__ == '__main__':
    main()
