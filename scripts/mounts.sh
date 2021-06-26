SSHD_CONFIG="$DATA_ROOT/sshd/sshd_config"

function generateSshdConfig {
    OUT_FILE="$SSHD_CONFIG"
    CHROOT_DIR="$DATA_ROOT/sources"
    SSH_KEY="$DATA_ROOT/sshd/sshd_host_key"

    echo "UsePrivilegeSeparation no" > "$OUT_FILE"
    echo "Port 2022" >> "$OUT_FILE"
    echo "HostKey $SSH_KEY" >> "$OUT_FILE"
    echo "" >> "$OUT_FILE"
    echo "Match User $USER" >> "$OUT_FILE"
    echo "ChrootDirectory $CHROOT_DIR" >> "$OUT_FILE"
}

function startSshd {
    SSH_PID_FILE="$CONFIG_ROOT"
    /usr/bin/sshd -f "$SSHD_CONFIG" -D &
}
