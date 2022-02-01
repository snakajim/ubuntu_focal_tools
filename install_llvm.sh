#!/bin/bash
#
# Install LLVM on Ubuntu20.04 platform
# Host linux is either x86_64 or aarch64
#
LLVM_VERSION="13.0.0"
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz"
LLVM_PREBUILD_AARCH64="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz"

#
# Function hostarch()
# set $HOSTARCH 
#
function hostarch () {
  HOSTARCH=`uname -m`
  if [ $HOSTARCH == "x86_64" ]; then
    HOSTARCH="x86_64"
  else
    if [ $HOSTARCH == "aarch64" ]; then
      HOSTARCH="aarch64"
    else
      HOSTARCH="unknown"
      echo "My HOSTARCH=$HOSTARCH, Program exit"
      exit
    fi
  fi
  echo "My HOSTARCH=$HOSTARCH"
}

# identify host architecture
hostarch

#
# install CMAKE 3.22.1 if not new
#
sudo apt -y update && sudo apt -y install build-essential wget git cmake g++ aria2 sudo && sudo apt -y autoremove
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ "$CMAKE_VERSION" -lt 31200 ]; then
  echo "upgrade cmake version"
  mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && \
  aria2c -x10 https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz
  tar -zxvf cmake-3.22.1.tar.gz
  sudo apt -y install libssl-dev openssl
  cd cmake-3.22.1 && cmake . && make -j`nproc`
  sudo make install && make clean
  export CMAKE_ROOT=/usr/local/share/cmake-3.22
  echo "# CMAKE_ROOT setting" >> ${HOME}/.bashrc
  echo "export CMAKE_ROOT=/usr/local/share/cmake-3.22" >> ${HOME}/.bashrc
  sudo ldconfig -v
  source ${HOME}/.bashrc
fi

#
# install LLVM ${LLVM_VERSION} if not available
#
which clang
ret=$?
if [ $ret == '0' ]; then
  CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
else
  CLANG_VERSION="0"
fi

FORCE_PREBUILD=1

if ( ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "0" ] ) || [ $HOSTARCH == "x86_64" ] ) && [ "$CLANG_VERSION" -lt 150000 ]; then
  echo "Your clang is not new. Need to update."
  echo `clang --version`
  if [ ! -f ${HOME}/tmp/llvm-project-${LLVM_VERSION}.src.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_URL
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f llvm-project-${LLVM_VERSION}.src.tar.xz && \
    tar xf llvm-project-${LLVM_VERSION}.src.tar && \
    cd llvm-project-${LLVM_VERSION}.src && mkdir -p build && cd build
  start_time=`date +%s`
  cmake -G Ninja -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER="/usr/bin/gcc" \
    -DCMAKE_CXX_COMPILER="/usr/bin/g++"\
    -DLLVM_ENABLE_PROJECTS="clang;llvm;lld" \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"\
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_${LLVM_VERSION}" \
    ../llvm && make -j`nproc`
  end_time=`date +%s`
  run_time=$((end_time - start_time))
  sudo make install && make clean && cd ../ && rm -rf build && cd ${HOME}
fi

if ( [ $HOSTARCH == "aarch64" ]  && [ $FORCE_PREBUILD == "1" ] ) && [ "$CLANG_VERSION" -lt 150000 ]; then
  echo "Your clang is not new. Need to update."
  echo `clang --version`
  if [ ! -f ${HOME}/tmp/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz ]; then
    mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_PREBUILD_AARCH64
  fi
  cd ${HOME}/tmp && unxz -k -T `nproc` -f clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz
  mkdir -p /usr/local/llvm_${LLVM_VERSION}
  cd ${HOME}/tmp && tar xf clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar --strip-components 1 -C /usr/local/llvm_${LLVM_VERSION}
fi

#
# Update ~/.bashrc if necesarry
#
grep LLVM_VERSION ${HOME}/.bashrc
ret=$?
if [ $ret == "1" ] && [ -d /usr/local/llvm_${LLVM_VERSION} ]; then
    echo "# " >> ${HOME}/.bashrc
    echo "# LLVM setting to \${LLVM_VERSION}"   >> ${HOME}/.bashrc
    echo "# " >> ${HOME}/.bashrc
    echo "export LLVM_VERSION=${LLVM_VERSION}" >> ${HOME}/.bashrc
    echo "export LLVM_DIR=/usr/local/llvm_\${LLVM_VERSION}">> ${HOME}/.bashrc
    echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  ${HOME}/.bashrc
    echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  ${HOME}/.bashrc
    # root /etc/skel
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "# LLVM setting to \${LLVM_VERSION}"   >> /etc/skel/.bashrc
    sudo echo "# " >> /etc/skel/.bashrc
    sudo echo "export LLVM_VERSION=${LLVM_VERSION}" >> /etc/skel/.bashrc
    sudo echo "export LLVM_DIR=/usr/local/llvm_\${LLVM_VERSION}">> /etc/skel/.bashrc
    sudo echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  /etc/skel/.bashrc
    sudo echo "export LLVM_CONFIG=\$LLVM_DIR/bin/llvm-config"   >>  /etc/skel/.bashrc
fi

echo "cat /proc/cpuinfo" > ${HOME}/tmp/run.log
cat /proc/cpuinfo  >> ${HOME}/tmp/run.log
echo "nproc" >> ${HOME}/tmp/run.log
nproc >> ${HOME}/tmp/run.log
echo "/usr/bin/g++ version" >> ${HOME}/tmp/run.log
/usr/bin/g++ --version >> ${HOME}/tmp/run.log
echo "install_llvm.sh costs $run_time [sec]." >> ${HOME}/tmp/run.log
echo ""
