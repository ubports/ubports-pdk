function createCaches {
    mkdir -p "$IMG_CACHE"
}

function clearCaches {
    if [ -d "$IMG_CACHE" ]; then
        rm -rf "$IMG_CACHE"
        find "$IMG_CACHE" -type f -name "hdd.raw" -exec rm {} \;
    fi
    echo "Cache cleared!"
}
