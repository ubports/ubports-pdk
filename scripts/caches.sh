function createCaches {
    mkdir -p "$IMG_CACHE"
}

function clearCaches {
    if [ -d "$IMG_CACHE" ]; then
        find "$IMG_CACHE" -type f -mindepth 2 -maxdepth 2 -name "efi_1.fd" -exec rm {} \;
        find "$IMG_CACHE" -type f -mindepth 2 -maxdepth 2 -name "efi_2.fd" -exec rm {} \;
        find "$IMG_CACHE" -type f -mindepth 2 -maxdepth 2 -name "hdd.raw" -exec rm {} \;
    fi
    echo "Cache cleared!"
}
