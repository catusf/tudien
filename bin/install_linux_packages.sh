#!/bin/bash

sudo apt-get update &&
sudo apt-get install -y dictzip systemd pandoc liblzo2-2 liblzo2-dev &&
sudo apt install -y ruby-full &&
ruby -v &&
#sudo gem install bundler &&
sudo gem install bundler -v 2.3.26 &&
#sudo gem install io-console -v 0.5.9 &&

sudo mv /etc/localtime /etc/localtime-backup &&
sudo ln -s /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime &&

git config --global log.date local
