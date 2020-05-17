# https://linuxize.com/post/how-to-build-docker-images-with-dockerfile/
# https://www.howtoforge.com/tutorial/how-to-create-docker-images-with-dockerfile/
# https://gist.github.com/croepha/cdaf30638109b1a949f35aa215a7c86d

# Use the official image as a parent image.
FROM poobuntu:latest
MAINTAINER Innovations Anonymous <InnovAnon-Inc@protonmail.com>

LABEL version="1.0"
LABEL maintainer="Innovations Anonymous <InnovAnon-Inc@protonmail.com>"
LABEL about="LLVM/Musl Install Notes Bash script ported to Dockerfile"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.license="PDL (Public Domain License)"
LABEL org.label-schema.name="LLVM/Musl toolchain install notes"
LABEL org.label-schema.url="InnovAnon-Inc.github.io/llvm-musl"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.vcs-url="https://github.com/InnovAnon-Inc/llvm-musl"

# Run the command inside your image filesystem.
# Copy the file from your host to your current location.
COPY dpkg.list .
RUN apt-fast install -y `cat dpkg.list`

ENV B /tmp

ENV OLD_PATH     ${PATH}
ARG HOSTCC=/usr/bin/cc
ENV HOSTCC       ${HOSTCC}
ENV NINJA_STATUS "[%f/%t %e] "
ENV TARGET_ARCH  x86_64-pc-linux-musl

ENV C_INCLUDE_PATH /usr/local/include

RUN mkdir -pv ${B}/src
# Set the working directory.
WORKDIR ${B}/src

RUN wget https://github.com/ninja-build/ninja/releases/download/v1.10.0/ninja-linux.zip
RUN unzip ninja-linux.zip
RUN chmod -v +x ninja
RUN install -v ninja /usr/local/bin/
RUN rm -v ninja-linux.zip

RUN wget http://gnu.spinellicreations.com/make/make-4.3.tar.lz
RUN tar xf make-4.3.tar.lz
RUN mkdir -pv ${B}/make-build
WORKDIR ${B}/make-build
RUN ${B}/src/make-4.3/configure
RUN make
RUN make install
WORKDIR ${B}/src
RUN rm -rf ${B}/make-build make-4.3 make-4.3.tar.lz

RUN wget https://github.com/Kitware/CMake/releases/download/v3.17.2/cmake-3.17.2.tar.gz
RUN tar xf cmake-3.17.2.tar.gz
RUN mkdir -pv ${B}/cmake-build
WORKDIR ${B}/cmake-build
#cmake -G Ninja -DCMAKE_BUILD_TYPE=Release $B/src/cmake && ninja install
RUN ${B}/src/cmake-3.17.2/bootstrap
RUN make
RUN make install
WORKDIR ${B}/src
RUN rm -rf ${B}/cmake-build cmake-3.17.2 cmake-3.17.2.tar.gz

RUN git clone --depth=1 https://github.com/madler/zlib
RUN mkdir -pv ${B}/zlib-build
WORKDIR ${B}/zlib-build
RUN cmake -G Ninja -DCMAKE_BUILD_TYPEP=Release ${B}/src/zlib
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf ${B}/zlib-build zlib

RUN wget https://www.python.org/ftp/python/3.8.3/Python-3.8.3rc1.tar.xz
RUN tar xf Python-3.8.3rc1.tar.xz
RUN mkdir -pv ${B}/python-build
WORKDIR ${B}/python-build
RUN ${B}/src/Python-3.8.3rc1/configure
RUN make
RUN make install
RUN ln -s python3 /usr/local/bin/python
WORKDIR ${B}/src
RUN rm -rf ${B}/python-build Python-3.8.3rc1 Python-3.8.3rc1.tar.xz

RUN git clone --depth=1 https://github.com/Z3Prover/z3
#RUN mkdir -pv ${B}/z3-build
#WORKDIR ${B}/z3-build
WORKDIR ${B}/src/z3
RUN python scripts/mk_make.py
WORKDIR build
RUN make
RUN make install
WORKDIR ${B}/src
#RUN rm -rf ${B}/z3-build z3
RUN rm -rf z3





RUN git clone --depth=1 --branch release/10.x https://github.com/llvm/llvm-project.git

RUN mkdir -pv ${B}/extra-build
WORKDIR       ${B}/extra-build
RUN cmake -G Ninja \
 -DCMAKE_BUILD_TYPE=Release \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 ${B}/src/llvm-project/llvm
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf    ${B}/extra-build

RUN mkdir -pv ${B}/extra-build
WORKDIR       ${B}/extra-build
RUN cmake -G Ninja \
 -DLLVM_ENABLE_PROJECTS='clang;compiler-rt' \
 -DCMAKE_BUILD_TYPE=Release \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 ${B}/src/llvm-project/llvm
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf    ${B}/extra-build

ENV CC  clang
ENV CXX clang++

RUN mkdir -pv ${B}/extra-build
WORKDIR       ${B}/extra-build
RUN cmake -G Ninja \
 -DCMAKE_BUILD_TYPE=Release \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 -DLLVM_ENABLE_PROJECTS='clang;compiler-rt;lld' \
 -DLLVM_ENABLE_LIBXML2=Off \
 ${B}/src/llvm-project/llvm
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf    ${B}/extra-build





#RUN git clone --depth=1 --branch release/10.x https://github.com/llvm/llvm-project.git
RUN mkdir -pv ${B}/stage1-build
WORKDIR ${B}/stage1-build
RUN cmake -G Ninja \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=${B}/stage1-prefix \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 -DLLVM_ENABLE_PROJECTS='clang;compiler-rt;lld' \
 -DLLVM_PARALLEL_LINK_JOBS=3 \
 -DLLVM_ENABLE_LIBXML2=Off \
 -DLLVM_ENABLE_LLD=On \
 -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_ARCH} \
 -DCLANG_DEFAULT_LINKER=lld \
 -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
 -DCLANG_DEFAULT_RTLIB=compiler-rt \
 -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${TARGET_ARCH} \
 ${B}/src/llvm-project/llvm
RUN ninja install

WORKDIR ${B}/stage1-prefix/bin
RUN ln -sv clang++ c++
RUN ln -sv clang   cc
RUN ln -sv llvm-ar ar

WORKDIR ${B}/src
RUN rm -rf ${B}/stage1-build



ENV CC              clang
ENV CXX             clang++
ENV LD              ld.lld
ENV PATH            ${B}/stage1-prefix/bin/:${OLD_PATH}
ENV LD_LIBRARY_PATH ${B}/stage1-prefix/lib/
ENV CFLAGS          " --sysroot ${B}/target1 "
ENV CXXFLAGS        ${CFLAGS}
ENV LDFLAGS         " --sysroot ${B}/target1 "

RUN git clone --depth=1 https://github.com/sabotage-linux/kernel-headers.git
WORKDIR ${B}/src/kernel-headers
RUN make ARCH=x86_64 prefix=${B}/target1 install
WORKDIR ${B}/src
RUN rm -rf kernel-headers



RUN wget https://musl.libc.org/releases/musl-1.2.0.tar.gz
RUN tar xf musl-1.2.0.tar.gz

RUN mkdir -pv ${B}/musl-build1
WORKDIR ${B}/musl-build1

RUN mkdir -pv ${B}/target1/lib/
RUN ln -sv . ${B}/target1/usr

RUN touch empty.c
RUN clang -Ofast -c empty.c       -o ${B}/target1/lib/crtbegin.o
RUN clang -Ofast -c empty.c -fPIC -o ${B}/target1/lib/crtbeginS.o
RUN clang -Ofast -c empty.c       -o ${B}/target1/lib/crtend.o
RUN clang -Ofast -c empty.c -fPIC -o ${B}/target1/lib/crtendS.o

#WORKDIR ${B}/musl-build1
RUN LIBCC="${B}/stage1-prefix/lib/clang/10.0.1/lib/linux/libclang_rt.builtins-x86_64.a" \
  ${B}/src/musl-1.2.0/configure --prefix=${B}/target1 --syslibdir=${B}/target1/lib
#RUN make -j $(nproc)
RUN make
RUN make install
#ENV _linker $( ls ${B}/target1/lib/ld-musl-* )
#RUN rm -v ${_linker}
#RUN ln -sv libc.so ${_linker}
RUN ln -sfv libc.so `ls ${B}/target1/lib/ld-musl-*`
WORKDIR ${B}/target1/bin
RUN ln -sv ../lib/libc.so ldd

WORKDIR ${B}/src
RUN rm -rf musl-1.2.0.tar.gz musl-1.2.0 musl-build1



# TODO this is borked.
#      it was like that when I got here,
#      but I probably made it worse
RUN git clone --depth=1 https://github.com/libunwind/libunwind
WORKDIR libunwind
RUN ./autogen.sh
RUN mkdir -pv ${B}/libunwind-build
WORKDIR ${B}/libunwind-build
RUN sed -i 's/LIBCRTS="-lgcc_s"/LIBCRTS=""/'  ${B}/src/libunwind/configure
RUN ${B}/src/libunwind/configure --prefix=${B}/target1 --enable-cxx-exceptions \
  --disable-tests --host=${TARGET_ARCH}
#RUN make -j $(nproc)
RUN make
RUN make install
WORKDIR ${B}/src
RUN rm -rf ${B}/libunwind-build libunwind

#RUN git clone --depth=1 https://github.com/pathscale/libcxxrt.git
#RUN mkdir -pv  ${B}/libcxxrt-build
#WORKDIR ${B}/libcxxrt-build
#RUN CXXFLAGS=" -nostdlib++ -lunwind -Wno-unused-command-line-argument " \
#  cmake -G Ninja ${B}/src/libcxxrt
#RUN ninja
#RUN cp -av lib/libcxxrt.* ${B}/target1/lib
#WORKDIR ${B}/src
#RUN rm -rf ${B}/libcxxrt-build libcxxrt

RUN mkdir -pv ${B}/libcxx
WORKDIR ${B}/libcxx
RUN CXXFLAGS="${CXXFLAGS} -D_LIBCPP_HAS_MUSL_LIBC -Wno-macro-redefined -nostdlib++" \
cmake -G Ninja \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=${B}/target1 \
 -DCMAKE_CROSSCOMPILING=True \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 -DLLVM_PARALLEL_LINK_JOBS=3 \
 -DLLVM_ENABLE_LLD=On \
 -DLLVM_TABLEGEN=${B}/stage1-prefix/bin/llvm-tblgen \
 -DLIBCXX_HAS_MUSL_LIBC=On \
 -DLIBCXX_SYSROOT=${B}/target1 \
 -DLIBCXX_CXX_ABI=libcxxrt  \
 -DLIBCXX_CXX_ABI_INCLUDE_PATHS="${B}/src/libcxxrt/lib;${B}/src/libcxxrt/src" \
 ${B}/src/llvm-project/libcxx
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf ${B}/libcxx

RUN mkdir -pv ${B}/stage2-build
WORKDIR ${B}/stage2-build
RUN cmake -G Ninja \
 -DCMAKE_SYSROOT=${B}/target1 \
 -DCMAKE_BUILD_TYPE=Release \
 -DCMAKE_INSTALL_PREFIX=${B}/target1 \
 -DCMAKE_CROSSCOMPILING=True \
 -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_ARCH} \
 -DLLVM_ENABLE_PROJECTS='clang;libcxx;libcxxabi;libunwind;compiler-rt;lld' \
 -DLLVM_TARGETS_TO_BUILD=X86 \
 -DLLVM_PARALLEL_LINK_JOBS=3 \
 -DLLVM_ENABLE_LLD=On \
 -DLLVM_ENABLE_LIBXML2=Off \
 -DLLVM_TABLEGEN=${B}/stage1-prefix/bin/llvm-tblgen \
 -DCLANG_TABLEGEN=${B}/stage1-build/bin/clang-tblgen \
 -DCLANG_DEFAULT_LINKER=lld \
 -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
 -DCLANG_DEFAULT_RTLIB=compiler-rt \
 -DLIBCXX_HAS_MUSL_LIBC=On \
 -DLIBCXX_SYSROOT=${B}/target1 \
 -DLIBCXXABI_USE_COMPILER_RT=YES \
 -DLIBCXXABI_USE_LLVM_UNWINDER=1 \
 -DLIBCXXABI_ENABLE_STATIC_UNWINDER=On \
 -DCOMPILER_RT_BUILD_SANITIZERS=Off \
 -DCOMPILER_RT_BUILD_XRAY=Off \
 -DCOMPILER_RT_BUILD_LIBFUZZER=Off \
 ${B}/src/llvm-project/llvm
RUN ninja install-unwind
RUN ninja install-cxxabi
RUN ninja install-cxx
RUN ninja install
WORKDIR ${B}/src
RUN rm -rf ${B}/stage2-build ${B}/src/llvm-project



RUN git clone --depth=1 --branch=1_31_stable git://git.busybox.net/busybox.git
RUN mkdir -pv $B/busybox-build
WORKDIR ${B}/src/busybox
RUN make O=${B}/busybox-build defconfig
# https://wiki.musl-libc.org/building-busybox.html
WORKDIR ${B}/busybox-build
#RUN make -j $(nproc) CC="${CC} -Ofast -Wno-ignored-optimization-argument -Wno-unused-command-line-argument" 
RUN make CC="${CC} -Ofast -Wno-ignored-optimization-argument -Wno-unused-command-line-argument" 
RUN cp -v busybox ${B}/target1/bin

# We cant simply use busybox --list or --install because can't assume
#  that the host can execute target binaries...
COPY print_applets.c .
RUN ${HOSTCC} ${B}/busybox-build/print_applets.c -o ${B}/busybox-build/print_applets.exec

WORKDIR ${B}/target1/bin
RUN for i in $(${B}/busybox-build/print_applets.exec ); \
  do ln -sfv ./busybox $i; \
  done
RUN ln -sv clang++ c++
RUN ln -sv clang   cc
RUN ln -sv llvm-ar ar
RUN ln -sv ld.lld  ld
WORKDIR ${B}/src
RUN rm -rf ${B}/busybox-build ${B}/src/busybox



RUN wget https://ftp.gnu.org/gnu/make/make-4.3.tar.lz
RUN tar xf make-4.3.tar.lz
RUN mkdir -pv ${B}/make-build
WORKDIR ${B}/make-build
RUN ${B}/src/make-4.3/configure --prefix=${B}/target1 --host=${TARGET_ARCH}
#RUN make -j $(nproc)
RUN make
RUN make install
WORKDIR ${B}/src
RUN rm -rf ${B}/make-build ${B}/src/make-4.3 ${B}/src/make-4.3.tar.lz



WORKDIR /

RUN apt-fast purge --autoremove -y `cat dpkg.list`
RUN ./poobuntu-clean.sh
RUN rm -v dpkg.list poobuntu-clean.sh



RUN mkdir -pv ${B}/target1/{src,proc,dev,etc,tmp} 

# if you were cross compiling, then you would need to get this
# onto the target arch, but we just setup a chroot

RUN cp -v /etc/resolv.conf ${B}/target1/etc/resolv.conf
RUN mount -vo bind     ${B}/src/  ${B}/target1/src/
RUN mount -vt proc     none       ${B}/target1/proc/
RUN mount -vt devtmpfs none       ${B}/target1/dev/
#RUN chroot ${B}/target1 /bin/sh



#git clone --depth=1 --branch v1.1.21 git://git.musl-libc.org/musl
#git clone --depth=1 https://github.com/ninja-build/ninja.git



# Inform Docker that the container is listening on the specified port at runtime.
#EXPOSE 8080

# Run the specified command within the container.
#CMD [ "npm", "start" ]

# Copy the rest of your app's source code from your host to your image filesystem.
#COPY . .
