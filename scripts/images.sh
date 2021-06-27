function createImage {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Creating images not implemented on $(uname -s), skipping."
        return 0
    fi

    createCaches

    if [ "$(uname -m)" == "aarch64" ] || [ "$(uname -p)" == "arm64" ]; then
        ARCH="arm64"
    else
        ARCH="amd64"
    fi

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
        printf "\t%s\n" "$i"
    done
}
