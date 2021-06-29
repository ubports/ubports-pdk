function initImageVars {
    if [ "$(uname -s)" == "Linux" ]; then
        if [ "$ARCH" == "arm64" ]; then
            EFI_1="/snap/qemu-ut-pdk/current/usr/share/qemu/edk2-aarch64-code.fd"
            EFI_2="/snap/qemu-ut-pdk/current/usr/share/qemu/edk2-arm-vars.fd"
            QEMU=qemu-ut-pdk.arm64
            QEMU_ARGS="-device virtio-vga,virgl=on \
                -display sdl,gl=on -netdev user,id=ethernet.0 \
                -device rtl8139,netdev=ethernet.0 \
                -device AC97 \
                -serial mon:stdio"
        else
            QEMU=qemu-ut-pdk.qemu-virgil
            QEMU_ARGS="-device virtio-vga,virgl=on \
                -display sdl,gl=on -netdev user,id=ethernet.0 \
                -device rtl8139,netdev=ethernet.0 \
                -device AC97 \
                -serial mon:stdio"
        fi

        if [ "$HOST_ARCH" == "$ARCH" ]; then
            QEMU_ARGS="-enable-kvm $QEMU_ARGS"
        else
            QEMU_ARGS="$QEMU_ARGS"
        fi
    elif [ "$(uname -s)" == "Darwin" ]; then
        if [ "$ARCH" == "arm64" ]; then
            EFI_1="$(dirname $(which qemu-img))/../share/qemu/edk2-aarch64-code.fd"
            EFI_2="$(dirname $(which qemu-img))/../share/qemu/edk2-arm-vars.fd"
            QEMU=qemu-system-aarch64
            QEMU_ARGS="\
                -cpu cortex-a72 \
                -device intel-hda -device hda-output \
                -device virtio-gpu-pci \
                -device virtio-keyboard-pci \
                -device virtio-net-pci,netdev=net \
                -device virtio-mouse-pci \
                -display cocoa,gl=es \
                -netdev user,id=net,ipv6=off \
                -serial mon:stdio"
        else
            QEMU=qemu-system-x86_64
            QEMU_ARGS="\
                -cpu Haswell-v4 \
                -device intel-hda -device hda-output \
                -device virtio-gpu-pci \
                -device virtio-keyboard-pci \
                -device virtio-net-pci,netdev=net \
                -device virtio-mouse-pci \
                -display cocoa,gl=es \
                -netdev user,id=net,ipv6=off \
                -serial mon:stdio"
        fi

        if [ "$HOST_ARCH" == "$ARCH" ]; then
            QEMU_ARGS="-machine virt,accel=hvf,highmem=off $QEMU_ARGS"
        else
            QEMU_ARGS="$QEMU_ARGS"
        fi
    fi
}

function createImage {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Creating images not implemented on $(uname -s), skipping."
        return 0
    fi

    createCaches

    $SCRIPTPATH/deps/rootfs-builder-debos/debos-docker \
        -t architecture:"\"$ARCH\"" \
        -m 5G $SCRIPTPATH/deps/rootfs-builder-debos/focal-pdk.yaml
}

function pullLatestImage {
    createCaches
    wget -P "$IMG_CACHE/$NAME" --continue "$PULL_URL"
    echo "Unpacking the archive"
    unxz "$IMG_CACHE/$NAME/$PULL_IMG_NAME"
    mv "$IMG_CACHE/$NAME/$IMG_NAME" "$IMG_CACHE/$NAME/hdd.raw"
    echo "ARCH=$ARCH" > "$IMG_CACHE/$NAME/info.sh"
}

function runImage {
    if [ ! -d "$IMG_CACHE/$NAME" ]; then
        echo "Cache directory for image '$NAME' doesn't exist."
        return 1
    fi
    if [ ! -f "$IMG_CACHE/$NAME/hdd.raw" ]; then
        echo "Hard disk for image '$NAME' doesn't exist."
        echo "Consider pulling or creating an image yourself."
        return 1
    fi

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

    $QEMU $QEMU_ARGS $QEMU_MEM_ARGS $EFI_ARGS \
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
