function initSettingsVars {
	if [ "$OS" == "Darwin" ]; then
	    SETTINGS_FILE="$DATA_ROOT/sshd/settings.dmg"
	elif [ "$OS" == "Linux" ] || [ "$OS" == "WSL" ]; then
	    SETTINGS_FILE="$DATA_ROOT/sshd/settings.raw"
	fi
}

function generateSettingsImage {
    echo "Generating image with settings"
    initSettingsVars
    if [ "$OS" == "Darwin" ]; then
        if [ -f "$SETTINGS_FILE" ]; then
            rm "$SETTINGS_FILE"
        fi
        hdiutil create -size 100m -fs FAT32 -volname PDKSETTINGS "$SETTINGS_FILE"
    elif [ "$OS" == "Linux" ] || [ "$OS" == "WSL" ]; then
        dd if=/dev/zero of="$SETTINGS_FILE" bs=1M count=100
        mkfs.vfat -F32 "$SETTINGS_FILE"
        fatlabel "$SETTINGS_FILE" PDKSETTINGS
    fi
}

function copySettingsIntoImage {
    echo "Copying settings to image"
    initSettingsVars
    if [ "$OS" == "Darwin" ]; then
        hdiutil attach "$SETTINGS_FILE"
        cp "$CONFIG_ROOT/config.sh" "/Volumes/PDKSETTINGS/config.sh"
        cp "$DATA_ROOT/sshd/id_rsa" "/Volumes/PDKSETTINGS/id_rsa"
        cp "$DATA_ROOT/sshd/id_rsa.pub" "/Volumes/PDKSETTINGS/id_rsa.pub"
        hdiutil detach "/Volumes/PDKSETTINGS"
    elif [ "$OS" == "Linux" ] || [ "$OS" == "WSL" ]; then
        MNT_DIR=$(mktemp -d)
        sudo mount "$SETTINGS_FILE" "$MNT_DIR"
        sudo cp "$CONFIG_ROOT/config.sh" "$MNT_DIR/config.sh"
        sudo cp "$DATA_ROOT/sshd/id_rsa" "$MNT_DIR/id_rsa"
        sudo cp "$DATA_ROOT/sshd/id_rsa.pub" "$MNT_DIR/id_rsa.pub"
        sudo umount "$MNT_DIR"
        rm -rf "$MNT_DIR"
    fi
}
