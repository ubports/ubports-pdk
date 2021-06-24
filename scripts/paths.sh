if [ "$SNAP_COMMON_DATA" != "" ]; then
    IMG_CACHE="$SNAP_COMMON_DATA/pdk-image-cache"
elif [ "$(uname -s)" == "Darwin" ]; then
    IMG_CACHE="$HOME/Library/Caches/UbuntuTouchPdk/pdk-image-cache"
fi
