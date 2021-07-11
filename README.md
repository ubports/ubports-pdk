# Platform Development Kit

A way to help the development of Ubuntu Touch


## Goals:

- Make debugging platform components easy
- Don't worry about porting
- Lower barrier to entry for contributors


## Installation:

- Linux with Snap:
  - `sudo snap install --edge ubports-pdk`
  - `sudo snap connect ubports-pdk:kvm`
  - `sudo snap connect ubports-pdk:network-control`
- macOS & other Linux: Clone this repository or download a copy of it from GitHub

## Usage:

For the snap version, use the command `ubports-pdk.pdk` instead of `ubuntu-touch-pdk`.

- `ubuntu-touch-pdk setup`: Sets up the environment and mounting capabilities for your development needs
- `ubuntu-touch-pdk pull`: Download the freshest development image (based on focal)
- `ubuntu-touch-pdk run`: Run the development VM instance

For more options, please run the command with the `-h` flag.


## Tutorial: Fetching package sources

When logged into the VM instance (user: root, password: root) you're able to clone UBports repositories using `ubports-clone`. Let's try that with `indicator-network`.

```
root@linux:~# ubports-clone indicator-network
```

This will download the sources from Git and make them available in your PDK workspace (configured during the `ubuntu-touch-pdk setup` step).

Within the VM instance you're able to access those files in `/pdk/sources`.


## Tutorial: Building package sources

Still logged into the VM instance, you're able to trigger a build of your cloned sources using `ubports-build`, ie for `indicator-network`:

```
root@linux:~# ubports-build indicator-network
```

This will copy your sources over to the VM, build the source code and publish Debian packages easily accessible from within your PDK workspace. For `indicator-network` those files will be located in `$PDK_WORKSPACE/sources/indicator-network`

The same Debian packages generated by the `ubports-build` command can be installed into the VM, like: `sudo apt install /pdk/sources/indicator-network/*.deb`


## Technical details:

- Preconfigured QEMU with OpenGL support
- Focus on Linux and macOS as host systems first
- Intel images on Intel hardware, ARM64 on ARM64 hardware (Mac M1)
- 20.04 off-the-shelf kernel
- Rootfs builds taken straight from Debos
- Utilities that wrap around Git and make it easier to pull sources
- Utilities around building and testing UT components