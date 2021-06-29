#!/bin/bash

set -e

echo "Installing prerequisites"
if [ "$OS" == "Darwin" ]; then
    brew install knazarov/qemu-virgl/qemu-virgl
    brew install wget
elif [ "$OS" == "Linux" ]; then
    sudo snap install --edge qemu-ut-pdk
    sudo snap connect qemu-ut-pdk:kvm
    if [ "$(id)" != *kvm* ]; then
        sudo usermod -aG kvm $USER
        echo "Set up KVM for $USER, logging out and back in is advised"
    fi
elif [ "$OS" == "WSL" ]; then
    echo "WSL still needs the prerequísites implemented..."
fi
