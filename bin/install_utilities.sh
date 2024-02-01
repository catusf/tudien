#!/bin/bash

# Install Git LFS module and fetch the big files
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash &&
sudo apt-get install git-lfs &&
git lfs install && 
git lfs pull &&

git submodule update --init --recursive &&
git config pull.rebase true
