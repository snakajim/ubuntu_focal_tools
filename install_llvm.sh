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
  uname -a | grep -q "x86_64 x86_64"
  ret1=$?
  uname -a | grep -q "aarch64 aarch64"
  ret2=$?
  if [ $ret1 -eq 0 ] && [ $ret2 -eq 1 ]; then
    HOSTARCH="x86_64"
  else
    if [ $ret1 -eq 1 ] && [ $ret2 -eq 0 ]; then
      HOSTARCH="aarch64"
    else
      HOSTARCH="unknown"
    fi
  fi
  echo "My HOSTARCH=$HOSTARCH"
}

# identify host architecture
hostarch

#
# install CMAKE 3.22.1 if not new
#
sudo apt -y update && sudo apt -y install build-essential wget git cmake g++ clang aria2 sudo && sudo autoremove
CMAKE_VERSION=$(cmake --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ "$CMAKE_VERSION" -lt 31200 ]; then
  echo "upgrade cmake version"
  mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && \
  aria2c -x10 https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1.tar.gz
  tar -zxvf cmake-3.22.1.tar.gz
  sudo apt -y install libssl-dev openssl
  cd cmake-3.22.1 && cmake . && make -j`nproc`
  sudo make install
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

if [ $HOSTARCH == "aarch64" ]; then
  if [ -f ${HOME}/download/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz ]; then
  echo "You have pre-build clang for aarch64, use this to short cut."
  cd ${HOME}/download && \
    unxz -k -T `nproc`  clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz && \
    sudo tar xvf clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar --strip-components 1 -C /usr/local
    sudo ldconfig -v
    read -p "LLVM ${LLVM_VERSION} install is done by pre-build. : (enter to exit) "
  exit
  else
  echo "Pre-build clang for aarch64 is not found."
  echo "Build & Install is selected(it takes 6-8 hours)."
  fi
fi

if [ "$CLANG_VERSION" -lt 130000 ]; then
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
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"\
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_${LLVM_VERSION}" \
    ../llvm && make -j`nproc`
  end_time=`date +%s`
  run_time=$((end_time - start_time))
  sudo make install && cd ${HOME}
  grep LLVM_VERSION ${HOME}/.bashrc
  ret=$?
  if [ $ret == "1" ]; then
    echo "# " >> ${HOME}/.bashrc
    echo "# LLVM setting to ${LLVM_VERSION}"   >> ${HOME}/.bashrc
    echo "# " >> ${HOME}/.bashrc
    echo "export LLVM_VERSION=${LLVM_VERSION}" >> ${HOME}/.bashrc
    echo "export LLVM_DIR=/usr/local/llvm_${LLVM_VERSION}">> ${HOME}/.bashrc
    echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  ${HOME}/.bashrc
    echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  ${HOME}/.bashrc
    echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  ${HOME}/.bashrc
  fi
else
  echo "Your clang is new. No need to update."
  echo `clang --version`
  run_time="default"  
fi

echo "cat /proc/cpuinfo" > ${HOME}/tmp/run.log
cat /proc/cpuinfo  >> ${HOME}/tmp/run.log
echo "nproc" >> ${HOME}/tmp/run.log
nproc >> ${HOME}/tmp/run.log
echo "/usr/bin/g++ version" >> ${HOME}/tmp/run.log
/usr/bin/g++ --version >> ${HOME}/tmp/run.log
echo "install_llvm.sh costs $run_time sec." >> ${HOME}/tmp/run.log
echo ""
