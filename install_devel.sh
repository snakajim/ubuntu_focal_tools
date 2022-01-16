#!/bin/bash
#
# Install useful tools for code developers in Ubuntu Focal
#
sudo apt-get -y update 
sudo apt-get -y upgrade
# useful for clang build
sudo apt-get -y install libc++-dev
sudo apt-get -y install gcc-multilib g++-multilib
sudo apt-get -y install apt-file
# useful for aarch64 cross compile
sudo apt-get -y install scons crossbuild-essential-armhf lib32z1
# useful for compile/link debug bug
sudo apt-get -y install mlocate
sudo updatedb
# clean up and finish
sudo apt-file update
sudo apt-get -y autoremove