CODENAME=Archangel
VERSION=0.0.0-rc0

if [ "$SNAP_USER_COMMON" != "" ]; then
    DATA_ROOT="$SNAP_USER_COMMON"
    MEM_TOTAL=$(awk '/MemTotal/ { printf "%d \n", $2/1024/1024 }' /proc/meminfo)

    if [ "$(uname -p)" == "aarch64" ]; then
        QEMU=qemu-ut-pdk.qemu-virgil.arm64
        QEMU_ARGS="-enable-kvm -device virtio-vga,virgl=on \
         -display sdl,gl=on -netdev user,id=ethernet.0 \
         -device rtl8139,netdev=ethernet.0 \
         -soundhw ac97 \
         -serial mon:stdio"
        IMG_NAME="ubuntu-touch-pdk-arm64.raw"
        PULL_IMG_NAME="${IMG_NAME}.xz"
        PULL_URL="https://ci.ubports.com/job/Platform%20Development%20Kit/job/pdk-vm-image-arm64/lastSuccessfulBuild/artifact/$PULL_IMG_NAME"
    else
        QEMU=qemu-ut-pdk.qemu-virgil
        QEMU_ARGS="-enable-kvm -device virtio-vga,virgl=on \
         -display sdl,gl=on -netdev user,id=ethernet.0 \
         -device rtl8139,netdev=ethernet.0 \
         -soundhw ac97 \
         -serial mon:stdio"
        IMG_NAME="ubuntu-touch-pdk-amd64.raw"
        PULL_IMG_NAME="${IMG_NAME}.xz"
        PULL_URL="https://ci.ubports.com/job/Platform%20Development%20Kit/job/pdk-vm-image-amd64/lastSuccessfulBuild/artifact/$PULL_IMG_NAME"
    fi
elif [ "$(uname -s)" == "Darwin" ]; then
    DATA_ROOT="$HOME/Library/Caches/UbuntuTouchPdk"
    MEM_TOTAL=$(sysctl -n hw.memsize | awk '{ printf "%d \n", $1/1024/1024/1024 }')

    if [ "$(uname -p)" == "arm" ]; then
        EFI_1="$(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd"
        EFI_2="$(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd"
        QEMU=qemu-system-aarch64
        QEMU_ARGS="-machine virt,accel=hvf,highmem=off \
         -cpu cortex-a72 -smp 4 \
         -device intel-hda -device hda-output \
         -device virtio-gpu-pci \
         -device virtio-keyboard-pci \
         -device virtio-net-pci,netdev=net \
         -device virtio-mouse-pci \
         -display cocoa,gl=es \
         -netdev user,id=net,ipv6=off \
         -serial mon:stdio"
        IMG_NAME="ubuntu-touch-pdk-arm64.raw"
        PULL_IMG_NAME="${IMG_NAME}.xz"
        PULL_URL="https://ci.ubports.com/job/Platform%20Development%20Kit/job/pdk-vm-image-arm64/lastSuccessfulBuild/artifact/$PULL_IMG_NAME"
    else
        QEMU=qemu-system-x86_64
        QEMU_ARGS="-machine virt,accel=hvf,highmem=off \
         -cpu Haswell-v4 -smp 4 \
         -device intel-hda -device hda-output \
         -device virtio-gpu-pci \
         -device virtio-keyboard-pci \
         -device virtio-net-pci,netdev=net \
         -device virtio-mouse-pci \
         -display cocoa,gl=es \
         -netdev user,id=net,ipv6=off \
         -serial mon:stdio"
        IMG_NAME="ubuntu-touch-pdk-amd64.raw"
        PULL_IMG_NAME="${IMG_NAME}.xz"
        PULL_URL="https://ci.ubports.com/job/Platform%20Development%20Kit/job/pdk-vm-image-amd64/lastSuccessfulBuild/artifact/$PULL_IMG_NAME"
    fi
fi

IMG_CACHE="$DATA_ROOT/pdk-image-cache"
MEM_VM=$((MEM_TOTAL/2))

if [ "$MEM_VM" -lt "1" ]; then
    MEM_VM=1
fi
if [ "$MEM_VM" -gt "4" ]; then
    MEM_VM=4
fi

QEMU_MEM_ARGS="-m ${MEM_VM}G"
