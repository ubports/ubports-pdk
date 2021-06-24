#!/bin/bash

set -e

HOST_OS=$(uname -s)

echo "Installing prerequisites"
if [ "$HOST_OS" == "Darwin" ]; then
    softwareupdate --install-rosetta
    brew install knazarov/qemu-virgl/qemu-virgl
elif [ "$HOST_OS" == "Linux" ]; then
    sudo snap install qemu-virgil
    if [ "$(id)" != *kvm* ]; then
        sudo usermod -aG kvm $USER
        echo "Set up KVM for $USER, logging out and back in is advised"
    fi
fi
