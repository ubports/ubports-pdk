#!/usr/bin/env bash

function warnMissingPlugs {
    # Only run in Snap environments
    if [ -z "$SNAP" ]; then
        return
    fi

    IS_KVM_CONNECTED=$(snapctl is-connected kvm && echo 1 || echo 0)
    IS_NETWORK_CONTROL_CONNECTED=$(snapctl is-connected network-control && echo 1 || echo 0)

    if [ "$IS_KVM_CONNECTED" != "1" ]; then
        echo "KVM use is not allowed, please run 'sudo snap connect ubports-pdk:kvm' and try again."
        CAUSE_FAIL=1
    fi
    if [ "$IS_NETWORK_CONTROL_CONNECTED" != "1" ]; then
        echo "Network control is not allowed, please run 'sudo snap connect ubports-pdk:network-control' and try again."
        CAUSE_FAIL=1
    fi

    # Heck, throw a group check in there too
    if getent group kvm | grep -q "\b$USER\b"; then
        echo "KVM group all set up, good."
    else
        echo "Make sure your user is in the 'kvm' group. To fix this run the following commands:"
        echo "sudo groupadd kvm"
        echo "sudo usermod -aG kvm $USER"
        CAUSE_FAIL=1
    fi

    if [ "$CAUSE_FAIL" != "" ]; then
        exit 1
    fi
}

function warnMissingData {
    IS_VALID=0
    echo "Please create and enter the directory path you want to set up."
    echo "This directory will contain your VM images and source code."

    while [ "$IS_VALID" == "0" ]; do
        printf "Path ($DEFAULT_DATA_ROOT): "
        read NEW_DATA_ROOT

        if [[ -z $NEW_DATA_ROOT ]]; then
            NEW_DATA_ROOT="$DEFAULT_DATA_ROOT"
        fi

        NEW_DATA_ROOT="$(realpath $NEW_DATA_ROOT)"
        if [ -d "$NEW_DATA_ROOT" ]; then
            IS_VALID=1
            continue;
        else
            read -p "Path does not exist, do you want create it? [Y/n]" yn
            case $yn in
                [Nn]* ) ;;
                * ) mkdir -p "$NEW_DATA_ROOT"; break;;
            esac
        fi

        echo "Please make sure the directory path is valid and exists"
    done

    # Check if this is on removable media and warn the user (Snap only)
    if [ "$SNAP" != "" ]; then
        if echo "$NEW_DATA_ROOT" | grep -q "^/media/"; then
            IS_REMOVABLE_CONNECTED=$(snapctl is-connected removable-media && echo 1 || echo 0)
            if [ "$IS_REMOVABLE_CONNECTED" != "1" ]; then
                echo "Removable media is not allowed, please run 'sudo snap connect ubports-pdk:removable-media' and try again"
                exit 1
            fi
        fi
    fi

    echo "DATA_ROOT=$NEW_DATA_ROOT" > "$CONFIG_ROOT/config.sh"
    echo "SRC_ROOT=$NEW_DATA_ROOT/sources" >> "$CONFIG_ROOT/config.sh"
    echo "USER=$USER" >> "$CONFIG_ROOT/config.sh"
    source "$CONFIG_ROOT/config.sh"
}

function tryInstallSshd {
    if [ "$(uname -s)" == "Linux" ]; then
        if [ -f /usr/bin/apt ]; then
            sudo apt install openssh-client openssh-server && \
                sudo systemctl enable --now ssh && \
                echo "SSH enabled successfully!"
        elif [ -f /usr/bin/dnf ]; then
            sudo dnf install openssh-clients openssh-server && \
                sudo systemctl enable --now sshd && \
                echo "SSH enabled successfully!"
        else
            echo "Unknown package manager used, please add support for it in UBports PDK".
        fi
    elif [ "$(uname -s)" == "Darwin" ]; then
        sudo systemsetup -setremotelogin on && echo "SSH enabled successfully!"
    fi
}

function checkSsh {
    # Only required on non-Snap Linux
    if [ "$(uname -s)" == "Linux" ] && [ -z "$SNAP" ]; then
        # Check if ssh or sshd is running and set the variable IS_INSTALLED to 1 if it is using pgrep
        pgrep -f "ssh" > /dev/null && IS_INSTALLED=1 || IS_INSTALLED=0
        
        if [ "$IS_INSTALLED" -ne 1 ]; then
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
    warnMissingPlugs
    warnMissingData

    if [ ! -d "$DATA_ROOT/sources" ]; then
        mkdir -p "$DATA_ROOT/sources"
    fi

    # Create empty sshd settings dir for settings image creation later on.
    # Who knows, maybe we need to stuff information there some day.
    if [ ! -d "$DATA_ROOT/sshd" ]; then
        mkdir -p "$DATA_ROOT/sshd"
    fi

    # Snap is done here, just needs ta check inside ya sshd settings
    # (on other platforms)
    if [ -z "$SNAP" ]; then
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
    fi
}
