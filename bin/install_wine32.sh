#!/bin/bash

# sudo dpkg --add-architecture i386

# sudo apt update

# wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -

# sudo apt --yes install software-properties-common

# sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main"

# sudo apt update

# sudo apt --yes install --install-recommends winehq-devel

# # sudo apt --yes install wine32

# wine --version

# sudo apt install -t parrot-backports wine32


# sudo dpkg --add-architecture i386

# sudo apt update

# sudo apt-add-repository -r 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'

# wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -

# sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main"

# sudo apt-get update

# sudo apt install --install-recommends winehq-devel

# wine ./bin/mobigen.exe

sudo dpkg --add-architecture i386 
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
sudo apt update
sudo apt install --install-recommends winehq-stable

# Verifies that it works 
wine ./bin/mobigen.exe
