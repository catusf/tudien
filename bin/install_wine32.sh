#!/bin/bash

sudo dpkg --add-architecture i386

sudo apt update

wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -

sudo apt install software-properties-common

sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main"

sudo apt update

sudo apt install --install-recommends winehq-stable

wine --version

wine ./bin/mobigen.exe --version
# sudo apt install -t parrot-backports wine32
