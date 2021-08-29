CODENAME=Archangel
VERSION=0.0.0-rc0

function initCommonVars {
    if [ "$(uname -s)" == "Linux" ]; then
        if [ "$SNAP_USER_COMMON" != "" ]; then
            CONFIG_ROOT="$SNAP_USER_COMMON"
        else
            CONFIG_ROOT="$HOME/.config/UbuntuTouchPdk"
        fi
        MEM_TOTAL=$(awk '/MemTotal/ { printf "%d \n", $2/1024/1024 }' /proc/meminfo)
        NPROCS="$(nproc --all)"
    elif [ "$(uname -s)" == "Darwin" ]; then
        CONFIG_ROOT="$HOME/Library/Caches/UbuntuTouchPdk"
        MEM_TOTAL=$(sysctl -n hw.memsize | awk '{ printf "%d \n", $1/1024/1024/1024 }')
        NPROCS="$(sysctl -n hw.ncpu)"
    fi

    DEFAULT_DATA_ROOT="$HOME/UbuntuTouchPdk"
    IMG_NAME="ubuntu-touch-pdk-$ARCH.raw"
    PULL_IMG_NAME="${IMG_NAME}.xz"
    ARTIFACTS_URL="https://ci.ubports.com/job/Platform%20Development%20Kit/job/pdk-vm-image-$ARCH/lastSuccessfulBuild/artifact"
    PULL_URL="$ARTIFACTS_URL/$PULL_IMG_NAME"

    MEM_VM=$((MEM_TOTAL/2))
    if [ "$MEM_VM" -lt "1" ]; then
        MEM_VM=1
    fi
    if [ "$MEM_VM" -gt "8" ]; then
        MEM_VM=8
    fi

    NPROC_VM=$((NPROCS-2))
    if [ "$NPROC_VM" -lt "2" ]; then
        NPROC_VM=2
    fi

    QEMU_MEM_ARGS="-m ${MEM_VM}G"
}
