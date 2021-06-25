# Platform Development Kit:

A way to help the development of Ubuntu Touch


## Goals:

- Make debugging platform components easy
- Don't worry about porting
- Lower barrier to entry for contributors


## Technical solution:

- Preconfigured QEMU with OpenGL support
- Focus on Linux and macOS as host systems first
- Intel images on Intel hardware, ARM64 on ARM64 hardware (Mac M1)
- 20.04 off-the-shelf kernel
- Rootfs builds taken straight from Debos
- LXD container with host-mounted project directories and tools for development
- Utilities that wrap around Git and make it easier to pull sources
- Utilities around building and testing UT components