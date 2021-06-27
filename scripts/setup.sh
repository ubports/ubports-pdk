function warnMissingData {
    IS_VALID=0
    echo "Please enter the directory path you want to set up"

    while [ "$IS_VALID" == "0" ]; do
        printf "Path: "
        read NEW_DATA_ROOT
        if [ -d "$NEW_DATA_ROOT" ]; then
            IS_VALID=1
            continue;
        fi
        echo "Please make sure the directory path is valid and exists"
    done

    echo "DATA_ROOT=$NEW_DATA_ROOT" > "$CONFIG_ROOT/config.sh"
    echo "SRC_ROOT=$NEW_DATA_ROOT/sources" >> "$CONFIG_ROOT/config.sh"
    echo "USER=$USER" >> "$CONFIG_ROOT/config.sh"
}

function setup {
    bash $SCRIPTPATH/scripts/prerequisites.sh
    warnMissingData

    if [ -f "$DATA_ROOT/sshd/id_rsa" ]; then
        rm "$DATA_ROOT/sshd/id_rsa"
    fi
    if [ -f "$DATA_ROOT/sshd/id_rsa.pub" ]; then
        rm "$DATA_ROOT/sshd/id_rsa.pub"
    fi

    ssh-keygen -q -t rsa -N '' -f "$DATA_ROOT/sshd/id_rsa"
    PUBKEY_CONTENTS=$(cat "$DATA_ROOT/sshd/id_rsa.pub")
    if grep -q "^$PUBKEY_CONTENTS" "$HOME/.ssh/authorized_keys"; then
        echo "Public key contents already registered, continuing"
    else
        if [ ! -d "$HOME/.ssh" ]; then
            mkdir "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
        fi
        echo "Inserting ssh key into authorized keys list"
        echo "$PUBKEY_CONTENTS" >> $HOME/.ssh/authorized_keys
    fi
}
