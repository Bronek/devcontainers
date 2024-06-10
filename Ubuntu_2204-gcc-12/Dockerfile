ARG DIST_TAG=22.04
FROM ubuntu:$DIST_TAG as build

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update ;\
    apt-get install -y --install-recommends \
    cmake ninja-build wget gcc g++ ;\
    apt-get clean

ARG MOLD_VERSION=2.31.0
RUN wget -O v${MOLD_VERSION}.tar.gz https://github.com/rui314/mold/archive/refs/tags/v${MOLD_VERSION}.tar.gz ;\
    tar -xzf v${MOLD_VERSION}.tar.gz ;\
    mv mold-${MOLD_VERSION} mold && cd mold ;\
    mkdir .build && cd .build ;\
    cmake -DCMAKE_GENERATOR=Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=/usr/bin/g++ .. ;\
    cmake --build . ;\
    cmake --install . --prefix dist --strip

FROM ubuntu:$DIST_TAG
COPY --from=build /root/mold/.build/dist/bin/mold /usr/local/bin/mold
COPY --from=build /root/mold/.build/dist/lib/mold/mold-wrapper.so /usr/local/lib/mold/mold-wrapper.so
COPY --from=build /root/mold/.build/dist/share/doc/mold/LICENSE /usr/local/share/doc/mold/LICENSE
COPY --from=build /root/mold/.build/dist/share/doc/mold/LICENSE.third-party /usr/local/share/doc/mold/LICENSE.third-party
COPY --from=build /root/mold/.build/dist/share/man/man1/mold.1 /usr/local/share/man/man1/mold.1
RUN cd /usr/local/bin/ && ln -s mold ld.mold ;\
    mkdir -p /usr/local/libexec/mold && cd /usr/local/libexec/mold/ && ln -s ../../bin/mold ld ;\
    cd /usr/local/share/man/man1/ && ln -s mold.1 ld.mold.1 ;\
    echo '/usr/local/lib/mold' > /etc/ld.so.conf.d/000-local-lib.conf ;\
    ldconfig -v

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
ARG CLANG_RELEASE=18
RUN set -ex ;\
    CODENAME=$( . /etc/os-release && echo $VERSION_CODENAME ) ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends ca-certificates wget gpg ;\
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /etc/apt/keyrings/llvm.gpg ;\
    printf "%s\n%s\n" \
      "deb [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      "deb-src [signed-by=/etc/apt/keyrings/llvm.gpg] https://apt.llvm.org/${CODENAME}/ llvm-toolchain-${CODENAME}-${CLANG_RELEASE} main" \
      | tee /etc/apt/sources.list.d/llvm.list ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
      lsb-release less vim curl git grep sed gdb zsh lcov cmake ninja-build ccache \
      python3 python3-pip python3-venv ;\
    apt-get install -t llvm-toolchain-${CODENAME}-${CLANG_RELEASE} -y --no-install-recommends \
      clang-${CLANG_RELEASE} clang-tools-${CLANG_RELEASE} clang-tidy-${CLANG_RELEASE} clang-format-${CLANG_RELEASE} \
      clangd-${CLANG_RELEASE} libc++-${CLANG_RELEASE}-dev libc++abi-${CLANG_RELEASE}-dev llvm-${CLANG_RELEASE} ;\
    apt-get clean

RUN update-alternatives --install \
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
    update-alternatives --auto clang ;\
    update-alternatives --auto llvm-cov ;\
    update-alternatives --auto clang-tidy ;\
    update-alternatives --auto clang-format ;\
    update-alternatives --auto clangd

ENV PATH=${PATH}:/usr/lib/llvm-${CLANG_RELEASE}/bin

RUN wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O  /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

RUN apt-get update ;\
    apt-get install -y --install-recommends \
    g++-12 libstdc++-12-dev ;\
    apt-get clean

RUN update-alternatives --install \
    /usr/bin/gcc gcc /usr/bin/gcc-12 100 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-12 \
    --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-12 \
    --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-12 \
    --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-12 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-12 \
    --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-tool-12 \
    --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-dump-12 ;\
    update-alternatives --auto gcc

ARG USER_HOME
ENV HOME=${USER_HOME}
WORKDIR ${HOME}

ENV VIRTUAL_ENV=${HOME}/venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV EDITOR=vim
ENV VISUAL=vim

RUN mkdir -p ${HOME}/.conan_profiles ;\
    mkdir -p ${HOME}/.conan ;\
    ln -s ${HOME}/.conan_profiles ${HOME}/.conan/profiles ;\
    pip --no-cache-dir install 'conan<2' ;\
    pip --no-cache-dir install 'gcovr'

ENV CCACHE_DIR=${HOME}/.ccache
RUN mkdir -p ${HOME}/.ccache

ENV PROFILE=gcc-12
RUN conan profile new ${PROFILE} --detect ;\
    ln -s ${HOME}/.conan_profiles/${PROFILE} ${HOME}/.conan_profiles/default ;\
    conan profile update settings.compiler=gcc ${PROFILE} ;\
    conan profile update settings.compiler.version=12 ${PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/bin/gcc-12", "cpp": "/usr/bin/g++-12"}' ${PROFILE} ;\
    grep -Fx "tools.cmake.cmaketoolchain:generator=Ninja" ${HOME}/.conan/global.conf &>/dev/null || echo tools.cmake.cmaketoolchain:generator=Ninja >> ${HOME}/.conan/global.conf

ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV CONAN_DEFAULT_PROFILE_PATH=${HOME}/.conan/profiles/${PROFILE}
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1

RUN echo "mkdir .build" > TODO.txt ;\
    echo "ln -s .build/compile_commands.json compile_commands.json" >> TODO.txt ;\
    echo "cd .build" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Debug" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Release" >> TODO.txt ;\
    echo "cmake -DCMAKE_TOOLCHAIN_FILE:FILEPATH=build/generators/conan_toolchain.cmake .." >> TODO.txt ;\
    echo "cmake --build ." >> TODO.txt ;\
    echo 'for i in $(ls ~/.conan/data/*/*/_/_/package/*/conaninfo.txt); '\
    'do head -20 $i | '\
    'grep -A10 -B10 build_type=Release | '\
    'grep -A10 -B10 os=Linux | '\
    'grep -A10 -B10 -E "compiler=gcc" | '\
    'grep -E "compiler.version=12|compiler.version=5" >/dev/null && '\
    'echo $(readlink -f $(dirname $i)/include); '\
    'done' >> TODO.txt

RUN cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile ;\
    echo 'export CCACHE_BASEDIR=$WORK' >> ~/.zprofile ;\
    echo "alias to-gcc='export CC=/usr/bin/gcc-12; export CXX=/usr/bin/g++-12; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias to-clang='export CC=/usr/bin/clang-${CLANG_RELEASE}; export CXX=/usr/bin/clang++-${CLANG_RELEASE}; env | grep --color=never -E \"^CC=|^CXX=\"'" >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
