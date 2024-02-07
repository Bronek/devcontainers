ARG DIST_TAG=22.04
FROM ubuntu:$DIST_TAG

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update ;\
    apt-get install -y --install-recommends \
    lsb-release vim wget curl git grep sed gdb zsh cmake ninja-build mold ccache \
    clang-tools-15 clang-tidy-15 clangd-15 clang-15 clang-format-15 \
    python3 python3-pip python3-venv ;\
    apt-get clean

RUN update-alternatives --install \
    /usr/bin/clang clang /usr/bin/clang-15 100 \
    --slave /usr/bin/clang++ clang++ /usr/bin/clang++-15 ;\
    update-alternatives --install \
    /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-15 100 ;\
    update-alternatives --install \
    /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-15 100 ;\
    update-alternatives --install \
    /usr/bin/clang-format clang-format /usr/bin/clang-format-15 100 ;\
    update-alternatives --install \
    /usr/bin/clangd clangd /usr/bin/clangd-15 100 ;\
    update-alternatives --auto clang ;\
    update-alternatives --auto llvm-cov ;\
    update-alternatives --auto clang-tidy ;\
    update-alternatives --auto clang-format ;\
    update-alternatives --auto clangd

ENV PATH=${PATH}:/usr/lib/llvm-15/bin

RUN wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O  /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

RUN apt-get update ;\
    apt-get install -y --install-recommends \
    g++-11 libstdc++-11-dev ;\
    apt-get clean

RUN update-alternatives --install \
    /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-11 \
    --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-11 \
    --slave /usr/bin/gcc-nm gcc-nm /usr/bin/gcc-nm-11 \
    --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-11 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-11 \
    --slave /usr/bin/gcov-tool gcov-tool /usr/bin/gcov-dump-11 \
    --slave /usr/bin/gcov-dump gcov-dump /usr/bin/gcov-tool-11 ;\
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

ENV PROFILE=gcc-11
RUN conan profile new ${PROFILE} --detect ;\
    ln -s ${HOME}/.conan_profiles/${PROFILE} ${HOME}/.conan_profiles/default ;\
    conan profile update settings.compiler=gcc ${PROFILE} ;\
    conan profile update settings.compiler.version=11 ${PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/bin/gcc-11", "cpp": "/usr/bin/g++-11"}' ${PROFILE} ;\
    grep -Fx "tools.cmake.cmaketoolchain:generator=Ninja" ${HOME}/.conan/global.conf &>/dev/null || echo tools.cmake.cmaketoolchain:generator=Ninja >> ${HOME}/.conan/global.conf

ENV CC=/usr/bin/gcc-11
ENV CXX=/usr/bin/g++-11
ENV CONAN_DEFAULT_PROFILE_PATH=${HOME}/.conan/profiles/${PROFILE}
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
ENV CMAKE_C_COMPILER=${CC}
ENV CMAKE_CXX_COMPILER=${CXX}
ENV CODE_COVERAGE_GCOV_TOOL=/usr/bin/gcov-11

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
    'grep -E "compiler.version=11|compiler.version=5" >/dev/null && '\
    'echo $(readlink -f $(dirname $i)/include); '\
    'done' >> TODO.txt

RUN cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile ;\
    echo 'export CCACHE_BASEDIR=$WORK' >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
