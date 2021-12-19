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
# install LLVM ${LLVM_VERSION} if not available
#
CLANG_VERSION=$(clang --version | awk 'NR<2 { print $3 }' | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')

if [ $HOSTARCH == "aarch64" ]; then
  if [ -f ${HOME}/download/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz ]; then
  echo "You have pre-build clang for aarch64, use this to short cut."
  cd ${HOME}/download && \
    unxz -k -T `nproc`  clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz && \
    sudo tar xvf clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar --strip-components 1 -C /usr/local
    sudo ldconfig -v
  exit
  else
  echo "Pre-build clang for aarch64 is not found."
  echo "Build & Install is selected(it takes 6-8 hours)."
  fi
fi

if [ "$CLANG_VERSION" -lt 120000 ]; then
  echo "Your clang is not new. Need to update."
  echo `clang --version`
  mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && aria2c -x10 $LLVM_URL
  unxz -k -T `nproc`  llvm-project-${LLVM_VERSION}.src.tar.xz && tar xf llvm-project-${LLVM_VERSION}.src.tar && \
    cd llvm-project-${LLVM_VERSION}.src && mkdir -p build && cd build
  cmake -G Ninja -G "Unix Makefiles"\
    -DCMAKE_C_COMPILER="/usr/bin/gcc" \
    -DCMAKE_CXX_COMPILER="/usr/bin/g++"\
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libc;libclc"
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;ARM"\
    -DCMAKE_INSTALL_PREFIX="/usr/local/llvm_${LLVM_VERSION}" \
    ../llvm && make -j`nproc`
  sudo make install && cd ${HOME}
  echo "# " >> ${HOME}/.bashrc
  echo "# LLVM setting to ${LLVM_VERSION}"   >> ${HOME}/.bashrc
  echo "# " >> ${HOME}/.bashrc
  echo "export LLVM_VERSION=${LLVM_VERSION}" >> ${HOME}/.bashrc
  echo "export LLVM_DIR=/usr/local/llvm_${LLVM_VERSION}">> ${HOME}/.bashrc
  echo "export PATH=\$LLVM_DIR/bin:\$PATH"   >>  ${HOME}/.bashrc
  echo "export LIBRARY_PATH=\$LLVM_DIR/lib:\$LIBRARY_PATH"   >>  ${HOME}/.bashrc
  echo "export LD_LIBRARY_PATH=\$LLVM_DIR/lib:\$LD_LIBRARY_PATH"   >>  ${HOME}/.bashrc
else
  echo "Your clang is new. No need to update."
  echo `clang --version`  
fi
