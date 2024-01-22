ARG DIST_TAG=39
FROM fedora:$DIST_TAG

WORKDIR /root

RUN dnf -y update ;\
    dnf -y install redhat-lsb python3.11 gcc \
    vim wget curl git grep sed gdb zsh cmake ninja-build ccache mold \
    clang clang-tools-extra libstdc++-static ;\
    dnf -y clean all

RUN wget -O /etc/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O /etc/skel/.zshrc  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrcv ;\
    chsh -s /bin/zsh

ARG USER_HOME
ENV HOME=${USER_HOME}
WORKDIR ${HOME}

ENV VIRTUAL_ENV=${HOME}/venv
RUN python3.11 -m venv ${VIRTUAL_ENV}
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV EDITOR=vim
ENV VISUAL=vim

RUN mkdir -p ${HOME}/.conan_profiles ;\
    mkdir -p ${HOME}/.conan ;\
    ln -s ${HOME}/.conan_profiles ${HOME}/.conan/profiles ;\
    pip --no-cache-dir install 'conan<2' ;\
    pip --no-cache-dir install 'gcovr'

# Fail build if unexpected gcc version
RUN gcc --version | grep -E "^gcc \(GCC\) 13"

ENV CCACHE_DIR=${HOME}/.ccache
RUN mkdir -p ${HOME}/.ccache

ENV PROFILE=gcc-13
RUN conan profile new ${PROFILE} --detect ;\
    ln -s ${HOME}/.conan_profiles/${PROFILE} ${HOME}/.conan_profiles/default ;\
    conan profile update settings.compiler=gcc ${PROFILE} ;\
    conan profile update settings.compiler.version=13 ${PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/bin/gcc", "cpp": "/usr/bin/g++"}' ${PROFILE} ;\
    grep -Fx "tools.cmake.cmaketoolchain:generator=Ninja" ${HOME}/.conan/global.conf &>/dev/null || echo tools.cmake.cmaketoolchain:generator=Ninja >> ${HOME}/.conan/global.conf

ENV CC=/usr/bin/gcc
ENV CXX=/usr/bin/g++
ENV CONAN_DEFAULT_PROFILE_PATH=${HOME}/.conan/profiles/${PROFILE}
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
ENV CMAKE_C_COMPILER=${CC}
ENV CMAKE_CXX_COMPILER=${CXX}

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
    'grep -E "compiler.version=13|compiler.version=5" >/dev/null && '\
    'echo $(readlink -f $(dirname $i)/include); '\
    'done' >> TODO.txt

RUN touch .zshrc.local ;\
    echo 'export CCACHE_BASEDIR=$WORK' >> ~/.zprofile
