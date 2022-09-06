function initImageVars {
    if [ "$(uname -s)" == "Linux" ]; then
        if [ "$ARCH" == "arm64" ]; then
            EFI_1="$SNAP/usr/share/qemu/edk2-aarch64-code.fd"
            EFI_2="$SNAP/usr/share/qemu/edk2-arm-vars.fd"
            if [ "$SNAP" == "" ]; then
                QEMU=qemu-system-aarch64
            else
                QEMU="$SNAP/usr/bin/qemu-system-aarch64"
            fi
            QEMU_ARGS="\
                -cpu cortex-a72 \
                -netdev user,id=ethernet.0,hostfwd=tcp:127.0.0.1:5555-:5555 \
                -device rtl8139,netdev=ethernet.0 \
                -device AC97 \
                -serial mon:stdio"
        else
            if [ "$SNAP" == "" ]; then
                QEMU=qemu-system-x86_64
            else
                QEMU="$SNAP/usr/bin/qemu-system-x86_64"
            fi
            QEMU_ARGS="\
                -cpu Haswell-v4 \
                -netdev user,id=ethernet.0,hostfwd=tcp:127.0.0.1:5555-:5555 \
                -device rtl8139,netdev=ethernet.0 \
                -device AC97 \
                -serial mon:stdio"
        fi

        if [ "$HOST_ARCH" == "$ARCH" ]; then
            QEMU_ARGS="-enable-kvm -device virtio-vga,virgl=on -display gtk,gl=on $QEMU_ARGS"
        else
            QEMU_ARGS="-machine virt -device virtio-gpu-pci,virgl=on -display gtk,gl=on $QEMU_ARGS"
        fi
        QEMU_ARGS="-device virtio-keyboard-pci -device virtio-mouse-pci $QEMU_ARGS"
    elif [ "$(uname -s)" == "Darwin" ]; then
        if [ "$ARCH" == "arm64" ]; then
            EFI_1="$(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd"
            EFI_2="$(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd"
            QEMU=qemu-system-aarch64
            QEMU_ARGS="\
                -cpu cortex-a72 \
                -device intel-hda -device hda-output \
                -device virtio-gpu-gl-pci \
                -device virtio-keyboard-pci \
                -device virtio-net-pci,netdev=net \
                -device virtio-mouse-pci \
                -display cocoa,gl=es \
                -netdev user,id=net,ipv6=off,hostfwd=tcp:127.0.0.1:5555-:5555 \
                -serial mon:stdio"
        else
            QEMU=qemu-system-x86_64
            QEMU_ARGS="\
                -cpu Haswell-v4 \
                -device intel-hda -device hda-output \
                -device virtio-gpu-gl-pci \
                -device virtio-keyboard-pci \
                -device virtio-net-pci,netdev=net \
                -device virtio-mouse-pci \
                -display cocoa,gl=es \
                -netdev user,id=net,ipv6=off,hostfwd=tcp:127.0.0.1:5555-:5555 \
                -serial mon:stdio"
        fi

        if [ "$HOST_ARCH" == "$ARCH" ]; then
            QEMU_ARGS="-machine virt,accel=hvf,highmem=off $QEMU_ARGS"
        else
            QEMU_ARGS="$QEMU_ARGS"
        fi
    fi
}

function pullLatestImage {
    createCaches
    if [ -e "$IMG_CACHE/$NAME/$IMG_NAME" ]; then
        rm -f "$IMG_CACHE/$NAME/$IMG_NAME"
    fi
    if [ -e "$IMG_CACHE/$NAME/$PULL_IMG_NAME" ]; then
        rm -f "$IMG_CACHE/$NAME/$PULL_IMG_NAME"
    fi
    wget -P "$IMG_CACHE/$NAME" --continue "$PULL_URL"
    echo "Unpacking the archive"

    set +e
    unxz "$IMG_CACHE/$NAME/$PULL_IMG_NAME"
    set -e

    mv "$IMG_CACHE/$NAME/$IMG_NAME" "$IMG_CACHE/$NAME/hdd.raw"
    echo "ARCH=$ARCH" > "$IMG_CACHE/$NAME/info.sh"
    echo "Pull successful!"
}

function runImage {
    source "$IMG_CACHE/$NAME/info.sh"

    EFI_ARGS=""
    if [ "$EFI_1" ]; then
        cp -a "$EFI_1" "$IMG_CACHE/$NAME/efi_1.fd"
        EFI_ARGS="$EFI_ARGS -drive if=pflash,format=raw,file=$IMG_CACHE/$NAME/efi_1.fd,readonly=on"
    fi
    if [ "$EFI_2" ]; then
        cp -a "$EFI_2" "$IMG_CACHE/$NAME/efi_2.fd"
        EFI_ARGS="$EFI_ARGS -drive if=pflash,format=raw,file=$IMG_CACHE/$NAME/efi_2.fd,discard=on"
    fi

    if [ "$VIRTIOFS_ACTIVE" == "1" ]; then
        VIRTIOFS_ARGS="\
            -chardev socket,id=char0,path=$VIRTIOFS_SOCK \
            -device vhost-user-fs-pci,chardev=char0,tag=myfs \
            -object memory-backend-memfd,id=mem,size=${MEM_VM}G,share=on \
            -numa node,memdev=mem"
    fi
    $QEMU $QEMU_ARGS $QEMU_MEM_ARGS $EFI_ARGS $VIRTIOFS_ARGS \
        -smp "$NPROC_VM" \
        -drive "if=virtio,format=raw,file=$IMG_CACHE/$NAME/hdd.raw,discard=on" \
        -drive "if=virtio,format=raw,file=$SETTINGS_FILE,readonly=on"
}

function listImages {
    createCaches
    printSeparator
    echo ""

    CACHE_IMAGES=$(ls "$IMG_CACHE")
    if [ "$CACHE_IMAGES" == "" ]; then
        echo "No images found"
        return 0
    fi

    echo "Cached images:"
    for i in $CACHE_IMAGES; do
        if [ ! -f "$IMG_CACHE/$i/hdd.raw" ]; then
            continue;
        fi
        if [ -f "$IMG_CACHE/$i/info.sh" ]; then
            IMG_ARCH=$(cat "$IMG_CACHE/$i/info.sh" | awk -F"=" '{ print $2 }')
        fi
        if [ "$IMG_ARCH" == "" ]; then
            IMG_ARCH="$ARCH"
        fi
        printf "\t- %s (%s)\n" "$i" "$IMG_ARCH"
        unset IMG_ARCH
    done
}
