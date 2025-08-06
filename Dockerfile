ARG CODENAME=bookworm
ARG GCC_RELEASE=13
FROM gcc:${GCC_RELEASE}-${CODENAME} AS gcc
RUN set -ex ;\
    find /usr/local/ -type f ;\
    cat /etc/ld.so.conf.d/*.conf ;\
    cat /etc/os-release ;\
    /usr/local/bin/gcc --version

ARG CODENAME=bookworm
FROM debian:$CODENAME AS mold

WORKDIR /root
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex ;\
    apt-get update ;\
    apt-get install -y --install-recommends \
    cmake ninja-build wget gcc g++ ;\
    apt-get clean

ARG MOLD_RELEASE=2.40.1
RUN set -ex ;\
    wget -O v${MOLD_RELEASE}.tar.gz https://github.com/rui314/mold/archive/refs/tags/v${MOLD_RELEASE}.tar.gz ;\
    tar -xzf v${MOLD_RELEASE}.tar.gz ;\
    mv mold-${MOLD_RELEASE} mold && cd mold ;\
    mkdir .build && cd .build ;\
    cmake -DCMAKE_GENERATOR=Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=/usr/bin/g++ .. ;\
    cmake --build . ;\
    cmake --install . --prefix dist --strip

ARG CODENAME=bookworm
FROM debian:$CODENAME
COPY --from=gcc /usr/local/ /usr/local/
COPY --from=gcc /etc/ld.so.conf.d/*.conf /etc/ld.so.conf.d/

WORKDIR /root
RUN set -ex ;\
    ldconfig -v ;\
    dpkg-divert --divert /usr/bin/gcc.orig --rename /usr/bin/gcc ;\
    dpkg-divert --divert /usr/bin/g++.orig --rename /usr/bin/g++ ;\
    dpkg-divert --divert /usr/bin/gfortran.orig --rename /usr/bin/gfortran ;\
    update-alternatives --install /usr/bin/cc cc /usr/local/bin/gcc 999 ;\
    update-alternatives --install \
      /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
      --slave /usr/bin/g++ g++ /usr/local/bin/g++ \
      --slave /usr/bin/gcc-ar gcc-ar /usr/local/bin/gcc-ar \
      --slave /usr/bin/gcc-nm gcc-nm /usr/local/bin/gcc-nm \
      --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/local/bin/gcc-ranlib \
      --slave /usr/bin/gcov gcov /usr/local/bin/gcov \
      --slave /usr/bin/gcov-tool gcov-tool /usr/local/bin/gcov-tool \
      --slave /usr/bin/gcov-dump gcov-dump /usr/local/bin/gcov-dump \
      --slave /usr/bin/lto-dump lto-dump /usr/local/bin/lto-dump ;\
    update-alternatives --auto cc ;\
    update-alternatives --auto gcc

COPY --from=mold /root/mold/.build/dist/bin/mold /usr/local/bin/mold
COPY --from=mold /root/mold/.build/dist/lib/mold/mold-wrapper.so /usr/local/lib/mold/mold-wrapper.so
COPY --from=mold /root/mold/.build/dist/share/doc/mold/LICENSE /usr/local/share/doc/mold/LICENSE
COPY --from=mold /root/mold/.build/dist/share/man/man1/mold.1 /usr/local/share/man/man1/mold.1
RUN set -ex ;\
    cd /usr/local/bin/ && ln -s mold ld.mold ;\
    mkdir -p /usr/local/libexec/mold && cd /usr/local/libexec/mold/ && ln -s ../../bin/mold ld ;\
    cd /usr/local/share/man/man1/ && ln -s mold.1 ld.mold.1 ;\
    echo '/usr/local/lib/mold' > /etc/ld.so.conf.d/000-local-lib-mold.conf ;\
    ldconfig -v

ARG GCC_RELEASE=13
ARG CLANG_RELEASE=18

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
WORKDIR ${HOME}
RUN set -ex ;\
    CODENAME=$( . /etc/os-release && echo $VERSION_CODENAME ) ;\
    apt-get update ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      ca-certificates gpg gpg-agent curl wget less vim xxd git grep sed gdb patch \
      build-essential zsh lcov cmake ninja-build ccache openssh-client jq libc6-dev \
      python3 python3-pip python3-venv python3-dev ;\
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg ;\
    printf "%s\n%s\n" \
      "deb [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      "deb-src [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      | tee /etc/apt/sources.list.d/llvm.list ;\
    apt-get update ;\
    apt-get install -t llvm-toolchain-${CODENAME}-${CLANG_RELEASE} -y --no-install-recommends \
      clang-${CLANG_RELEASE} clang-tools-${CLANG_RELEASE} \
      clang-tidy-${CLANG_RELEASE} clang-format-${CLANG_RELEASE} \
      clangd-${CLANG_RELEASE} libc++-${CLANG_RELEASE}-dev \
      libc++abi-${CLANG_RELEASE}-dev llvm-${CLANG_RELEASE}-dev ;\
    apt-get clean

RUN set -ex ;\
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang++-${CLANG_RELEASE} 999 ;\
    update-alternatives --install \
      /usr/bin/clang clang /usr/bin/clang-${CLANG_RELEASE} 100 \
      --slave /usr/bin/clang++ clang++ /usr/bin/clang++-${CLANG_RELEASE} ;\
    update-alternatives --install \
      /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clang-format clang-format /usr/bin/clang-format-${CLANG_RELEASE} 100 ;\
    update-alternatives --install \
      /usr/bin/clangd clangd /usr/bin/clangd-${CLANG_RELEASE} 100 ;\
    update-alternatives --auto cc ;\
    update-alternatives --auto clang ;\
    update-alternatives --auto llvm-cov ;\
    update-alternatives --auto clang-tidy ;\
    update-alternatives --auto clang-format ;\
    update-alternatives --auto clangd

ENV PATH=${PATH}:/usr/lib/llvm-${CLANG_RELEASE}/bin

RUN set -ex ;\
    wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O  /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

ENV VIRTUAL_ENV=${HOME}/venv
RUN set -ex ;\
    python3 -m venv ${VIRTUAL_ENV}
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV EDITOR=vim
ENV VISUAL=vim

ENV CCACHE_DIR=${HOME}/.ccache
RUN set -ex ;\
    mkdir -p ${HOME}/.conan_profiles ;\
    mkdir -p ${HOME}/.conan2 ;\
    ln -s ${HOME}/.conan_profiles ${HOME}/.conan2/profiles ;\
    pip --no-cache-dir install 'conan' ;\
    pip --no-cache-dir install 'gcovr' ;\
    pip --no-cache-dir install 'clang-format==18.1.8' ;\
    mkdir -p ${HOME}/.ccache

ENV PROFILE_GCC=gcc-${GCC_RELEASE}
RUN set -ex ;\
    export CC=/usr/bin/gcc ;\
    export CXX=/usr/bin/g++ ;\
    conan profile detect ;\
    sed -i -e 's|^compiler\.cppstd=.*$|compiler.cppstd=20|' ~/.conan2/profiles/default ;\
    echo "[conf]" >>  ~/.conan2/profiles/default ;\
    echo "tools.build:compiler_executables={'c': '${CC}', 'cpp': '${CXX}'}" >>  ~/.conan2/profiles/default ;\
    mv ~/.conan2/profiles/default ~/.conan2/profiles/${PROFILE_GCC}

ENV PROFILE_CLANG=clang-${CLANG_RELEASE}
RUN set -ex ;\
    export CC=/usr/bin/clang ;\
    export CXX=/usr/bin/clang++ ;\
    conan profile detect ;\
    sed -i -e 's|^compiler\.cppstd=.*$|compiler.cppstd=20|' ~/.conan2/profiles/default ;\
    echo "[conf]" >>  ~/.conan2/profiles/default ;\
    echo "tools.build:compiler_executables={'c': '${CC}', 'cpp': '${CXX}'}" >>  ~/.conan2/profiles/default ;\
    mv ~/.conan2/profiles/default ~/.conan2/profiles/${PROFILE_CLANG}

RUN set -ex ;\
    ln -s ${PROFILE_GCC} ${HOME}/.conan_profiles/default

ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1

RUN set -ex ;\
    echo "conan export --version 1.1.10 external/snappy" >> TODO.txt ;\
    echo "conan export --version 4.0.3 external/soci" >> TODO.txt ;\
    echo "ln -s .build/compile_commands.json compile_commands.json" >> TODO.txt ;\
    echo "mkdir .build" >> TODO.txt ;\
    echo "cd .build" >> TODO.txt ;\
    echo "export CMAKE_BUILD_TYPE=Debug" ;\
    echo 'conan install .. --output-folder . --build missing --settings build_type=$CMAKE_BUILD_TYPE' >> TODO.txt ;\
    echo "cmake -Dwextra=ON -Dwerr=ON -Dxrpld=ON -Dtests=ON -DCMAKE_TOOLCHAIN_FILE:FILEPATH=build/generators/conan_toolchain.cmake .." >> TODO.txt ;\
    echo "cmake --build ." >> TODO.txt ;\
    echo 'cd ~/.conan2/p/b; for i in $(ls -d */*); do ls -d $i/include 1>/dev/null 2>&1 && (grep -A10 -B10 -E '^build_type=Release$' $i/conaninfo.txt | grep -A10 -B10 -E '^compiler=gcc$' | grep -E '^os=Linux$' ) 1>/dev/null 2>&1 && printf "-isystem%s/include, " "$(realpath $i)"; done' >> TODO.txt ;\
    echo 'cd ~/.conan2/p; for i in $(ls -d */*); do ls -d $i/include 1>/dev/null 2>&1 && ls -l $i/conaninfo.txt 1>/dev/null 2>&1 && printf "-isystem%s/include, " "$(realpath $i)"; done' >> TODO.txt

RUN set -ex ;\
    cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    printf "python\nimport sys\nsys.path.insert(0, '/usr/share/gcc/python')\nfrom libstdcxx.v6.printers import register_libstdcxx_printers\nregister_libstdcxx_printers(None)\nend\n" >> ~/.gdbinit ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile ;\
    echo 'export CCACHE_BASEDIR=$WORK' >> ~/.zprofile ;\
    echo "alias to-gcc='export CC=/usr/bin/gcc; export CXX=/usr/bin/g++; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias to-clang='export CC=/usr/bin/clang; export CXX=/usr/bin/clang++; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
