#!/bin/bash

set -e

HOST_OS=$(uname -s)

echo "Installing prerequisites"
if [ "$HOST_OS" == "Darwin" ]; then
    brew install fredldotme/homebrew-qemu-virgl/qemu-virgl
    brew install wget
    brew install coreutils
elif [ "$HOST_OS" == "Linux" ]; then
    # Only necessary in non-Snap environments
    if [ -n "$SNAP" ]; then
        sudo snap install --edge qemu-ut-pdk
        sudo snap connect qemu-ut-pdk:kvm
        # Heck, throw a group check in there too
        if getent group kvm | grep -q "\b$USER\b"; then
            echo "KVM group all set up, good."
        else
            echo "Make sure your user is in the 'kvm' group. To fix this run the following commands:"
            echo "sudo groupadd kvm"
            echo "sudo usermod -aG kvm $USER"
            exit 1
        fi
    fi
fi
