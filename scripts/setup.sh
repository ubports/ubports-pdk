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
    source "$CONFIG_ROOT/config.sh"
}

function tryInstallSshd {
    if [ "$(uname -s)" == "Linux" ]; then
        if [ -f /usr/bin/apt ]; then
            sudo apt install openssh-server && \
                sudo systemctl enable ssh && \
                echo "SSH enabled successfully!"
        else
            echo "Unknown package manager used, please add support for it in UBports PDK".
        fi
    elif [ "$(uname -s)" == "Darwin" ]; then
        sudo systemsetup -setremotelogin on && echo "SSH enabled successfully!"
    fi
}

function checkSsh {
    if [ "$(uname -s)" == "Linux" ]; then
        systemctl status ssh 1&> /dev/null
        if [ "$?" != "0" ]; then
            echo "WARNING: The OpenSSH server seems to be missing or not activated, please install it using your package manager."
            while true; do
                read -p "Would you like to do that automatically now [y/n]? " yn
                case $yn in
                    [Yy]* ) tryInstallSshd; break;;
                    [Nn]* ) break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        fi
    elif [ "$(uname -s)" == "Darwin" ]; then
        OUTPUT=$(sudo systemsetup -getremotelogin)
        if [ "$OUTPUT" != "Remote Login: On" ]; then
            echo "WARNING: SSH doesn't seem to be enabled!"
            while true; do
                read -p "Would you like to enable it now [y/n]? " yn
                case $yn in
                    [Yy]* ) tryInstallSshd; break;;
                    [Nn]* ) break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        fi
    fi
}

function setup {
    bash $SCRIPTPATH/scripts/prerequisites.sh
    warnMissingData

    if [ ! -d "$DATA_ROOT/sources" ]; then
        mkdir -p "$DATA_ROOT/sources"
    fi
    if [ ! -d "$DATA_ROOT/sshd" ]; then
        mkdir -p "$DATA_ROOT/sshd"
    fi
    if [ -f "$DATA_ROOT/sshd/id_rsa" ]; then
        rm "$DATA_ROOT/sshd/id_rsa"
    fi
    if [ -f "$DATA_ROOT/sshd/id_rsa.pub" ]; then
        rm "$DATA_ROOT/sshd/id_rsa.pub"
    fi

    checkSsh

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
