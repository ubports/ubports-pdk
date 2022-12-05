#!/usr/bin/env bash

function initSettingsVars {
    if [ "$(uname -s)" == "Darwin" ]; then
        SETTINGS_FILE="$DATA_ROOT/sshd/settings.dmg"
    elif [ "$(uname -s)" == "Linux" ]; then
        SETTINGS_FILE="$DATA_ROOT/sshd/settings.raw"
        IS_MTOOLS_INSTALLED=$(which mtools >/dev/null && echo 1 || echo 0)
    fi
}

function generateSettingsImage {
    echo "Generating image with settings"
    initSettingsVars
    if [ "$(uname -s)" == "Darwin" ]; then
        if [ -f "$SETTINGS_FILE" ]; then
            rm "$SETTINGS_FILE"
        fi
        hdiutil create -size 100m -fs FAT32 -volname PDKSETTINGS "$SETTINGS_FILE"
    elif [ "$(uname -s)" == "Linux" ]; then
        dd if=/dev/zero of="$SETTINGS_FILE" bs=1M count=100
        mkfs.vfat -F32 "$SETTINGS_FILE"
        fatlabel "$SETTINGS_FILE" PDKSETTINGS
    fi
}

function copySettingsIntoImage {
    echo "Copying settings to image"
    initSettingsVars
    if [ "$(uname -s)" == "Darwin" ]; then
        hdiutil attach "$SETTINGS_FILE"
        cp "$CONFIG_ROOT/config.sh" "/Volumes/PDKSETTINGS/config.sh"
        cp "$DATA_ROOT/sshd/id_rsa" "/Volumes/PDKSETTINGS/id_rsa"
        cp "$DATA_ROOT/sshd/id_rsa.pub" "/Volumes/PDKSETTINGS/id_rsa.pub"
        hdiutil detach "/Volumes/PDKSETTINGS"
    elif [ "$(uname -s)" == "Linux" ]; then
        # Snap: No contents required right now
        if [ "$SNAP" != "" ]; then
            return
        fi

        if [ "$IS_MTOOLS_INSTALLED" == "1" ]; then
            echo "Using mtools to create a settings image"
            mcopy -i "$SETTINGS_FILE" "$CONFIG_ROOT/config.sh" ::
            mcopy -i "$SETTINGS_FILE" "$DATA_ROOT/sshd/id_rsa" ::
            mcopy -i "$SETTINGS_FILE" "$DATA_ROOT/sshd/id_rsa.pub" ::
        else
            echo "Using sudo-based settings image generation..."
            MNT_DIR=$(mktemp -d)
            sudo mount "$SETTINGS_FILE" "$MNT_DIR"
            sudo cp "$CONFIG_ROOT/config.sh" "$MNT_DIR/config.sh"
            sudo cp "$DATA_ROOT/sshd/id_rsa" "$MNT_DIR/id_rsa"
            sudo cp "$DATA_ROOT/sshd/id_rsa.pub" "$MNT_DIR/id_rsa.pub"
            sudo umount "$MNT_DIR"
            rm -rf "$MNT_DIR"
        fi
    fi
}

function startVirtiofsd {
    # Return immediately in non-Snap environments
    if [ -n "$SNAP" ]; then
        return
    fi
    VIRTIOFS_SOCK="$SNAP_USER_DATA/$NAME-vhost-fs.sock"
    $SNAP/usr/libexec/virtiofsd \
        --socket-path="$VIRTIOFS_SOCK" \
        -o source="$SRC_ROOT" \
        -o allow_root \
        -o allow_direct_io \
        -o xattr \
        -o writeback \
        -o readdirplus \
        -o posix_lock \
        -o flock \
        -f &

    while [ ! -e "$VIRTIOFS_SOCK" ]; do
        sleep 0.1
    done
    VIRTIOFS_ACTIVE=1
}
