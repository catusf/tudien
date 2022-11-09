#!/bin/bash

sudo dpkg --add-architecture i386  &&
sudo mkdir -pm755 /etc/apt/keyrings &&
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key &&
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/winehq-bionic.sources &&
sudo apt install --install-recommends winehq-stable &&

# Verifies that it works 
wine ./bin/mobigen/mobigen.exe
