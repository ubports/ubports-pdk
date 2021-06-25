#!/bin/bash

set -e

HOST_OS=$(uname -s)

echo "Installing prerequisites"
if [ "$HOST_OS" == "Darwin" ]; then
    #if [ "$(arch)" == "arm" ];
    #   softwareupdate --install-rosetta
    #fi
    brew install knazarov/qemu-virgl/qemu-virgl
    brew install wget
elif [ "$HOST_OS" == "Linux" ]; then
    sudo snap install --edge qemu-ut-pdk
    sudo snap connect qemu-virgil:kvm
    if [ "$(id)" != *kvm* ]; then
        sudo usermod -aG kvm $USER
        echo "Set up KVM for $USER, logging out and back in is advised"
    fi
fi
