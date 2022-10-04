#!/bin/bash
# This script is prepared for Ubuntu20.04 LTS, you may need tuning for other OS/version
#

VERILATOR_REV="216"
URL_VERILATOR="https://github.com/verilator/verilator/tarball/v4.${VERILATOR_REV}"

# dependencies update
sudo apt-get update
sudo apt-get install -y build-essential autoconf flex bison g++ 

#
# set CMAKE variable based on clang version.
#
which clang
ret=$?
if [ $ret == '0' ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
else
  CLANG_VERSION="0"
fi

if [ "$CLANG_VERSION" -gt 130000 ]; then
  echo "use clang for build tool"
  export CC=`which clang`
  export CXX=`which clang++`
  export LD=`which lld`
  export CMAKE_CXX_COMPILER=`which clang++`
  export CMAKE_C_COMPILER=`which clang`
  export CMAKE_LINKER=`which lld`
else
  echo "use gcc for build tool"
  export CC=`which gcc`
  export CXX=`which g++`
  export LD=`which ld.gold`
  export CMAKE_CXX_COMPILER=`which gcc++`
  export CMAKE_C_COMPILER=`which gcc`
  export CMAKE_LINKER=`which ld.gold`
fi

#
# install verilator 4_${VERILATOR_REV}
#
unset VERILATOR_ROOT 
mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && rm -rf ${HOME}/tmp/verilator 
mkdir -p verilator && wget --no-check-certificate https://github.com/verilator/verilator/tarball/v4.${VERILATOR_REV} -O verilator-v4.${VERILATOR_REV}.tgz
cd ${HOME}/tmp && tar -xvf verilator-v4.${VERILATOR_REV}.tgz -C verilator --strip-components 1
start_time=`date +%s`
cd ${HOME}/tmp/verilator && autoconf && \
  ./configure --prefix=/usr/local/verilator_4_${VERILATOR_REV} \
  CC=$CC \
  CXX=$CXX
make -j`nproc`
sudo make install
end_time=`date +%s`
run_time=$((end_time - start_time))
cd ${HOME}/tmp/verilator && make clean
sudo ln -sf /usr/local/verilator_4_${VERILATOR_REV}/bin/verilator* /usr/local/verilator_4_${VERILATOR_REV}/share/verilator/bin/
#cd ${HOME}/tmp/verilator && make clean

#
# report log
#
echo "cat /proc/cpuinfo" >> ${HOME}/run_verilator${VERILATOR_REV}.log
cat /proc/cpuinfo  >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "nproc" >> ${HOME}/run_verilator${VERILATOR_REV}.log
nproc >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "tool chain version" >> ${HOME}/run_verilator${VERILATOR_REV}.log
$CC --version >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo "install_verilator.sh costs $run_time [sec]." >> ${HOME}/run_verilator${VERILATOR_REV}.log
echo ""

#
# .bashrc set
#
cd ${HOME} && \
  echo "# " >> .bashrc
cd ${HOME} && \
  echo "# verilator setting" >> .bashrc
cd ${HOME} && \
  echo "export VERILATOR_ROOT=/usr/local/verilator_4_${VERILATOR_REV}/share/verilator">> .bashrc
cd ${HOME} && \
  echo "export PATH=\$VERILATOR_ROOT/bin:\$PATH" >> .bashrc
cd /etc/skel && \
  sudo echo "# " >> .bashrc
cd /etc/skel && \
  sudo echo "# verilator setting" >> .bashrc
cd /etc/skel && \
  sudo echo "export VERILATOR_ROOT=/usr/local/verilator_4_${VERILATOR_REV}/share/verilator">> .bashrc
cd /etc/skel && \
  sudo echo "export PATH=\$VERILATOR_ROOT/bin:\$PATH" >> .bashrc
