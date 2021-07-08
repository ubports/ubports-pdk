#!/bin/bash

set -e

HOST_OS=$(uname -s)

echo "Installing prerequisites"
if [ "$HOST_OS" == "Darwin" ]; then
    brew install knazarov/qemu-virgl/qemu-virgl
    brew install wget
elif [ "$HOST_OS" == "Linux" ]; then
    # Only necessary in non-Snap environments
    if [ "$SNAP_USER_COMMON" == "" ]; then
        sudo snap install --edge qemu-ut-pdk
        sudo snap connect qemu-ut-pdk:kvm
        if [ "$(id)" != *kvm* ]; then
            sudo usermod -aG kvm $USER
            echo "Set up KVM for $USER, logging out and back in is advised"
        fi
    fi
fi
