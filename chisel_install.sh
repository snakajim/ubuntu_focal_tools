#!/bin/bash
# This script is prepared for Ubuntu20.04 LTS, you may need tuning for other OS/version
#

# see https://github.com/chipsalliance/chisel3/blob/master/SETUP.md

sudo apt-get -y install default-jdk git cmake autoconf g++ flex bison aria2 openssl
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
sudo apt-get -y update
sudo apt-get -y install sbt

# install git > 2.34
sudo apt-get -y install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.34.0.tar.gz
tar zxvf git-2.34.0.tar.gz && cd git-2.34.0 && make -j`nproc` && sudo make prefix=/usr install


# Clone and build the Chisel library:

CHISEL3_REV="v3.4.4"
mkdir -p ${HOME}/work/$CHISEL3_REV && cd ${HOME}/work/$CHISEL3_REV
git clone https://github.com/chipsalliance/chisel3.git -b $CHISEL3_REV
cd ${HOME}/work/$CHISEL3_REV/chisel3 && sbt compile
