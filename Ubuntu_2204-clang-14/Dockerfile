ARG DIST_TAG=22.04
FROM ubuntu:$DIST_TAG

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update ;\
    apt-get install -y --install-recommends \
    lsb-release vim wget curl git grep sed gdb zsh cmake ninja-build mold ccache \
    clang-tools-14 clang-tidy-14 clangd-14 clang-14 clang-format-14 \
    python3 python3-pip python3-venv ;\
    apt-get clean

RUN update-alternatives --install \
    /usr/bin/clang clang /usr/bin/clang-14 100 \
    --slave /usr/bin/clang++ clang++ /usr/bin/clang++-14 ;\
    update-alternatives --install \
    /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-14 100 ;\
    update-alternatives --install \
    /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-14 100 ;\
    update-alternatives --install \
    /usr/bin/clang-format clang-format /usr/bin/clang-format-14 100 ;\
    update-alternatives --install \
    /usr/bin/clangd clangd /usr/bin/clangd-14 100 ;\
    update-alternatives --auto clang ;\
    update-alternatives --auto llvm-cov ;\
    update-alternatives --auto clang-tidy ;\
    update-alternatives --auto clang-format ;\
    update-alternatives --auto clangd

ENV PATH=${PATH}:/usr/lib/llvm-14/bin

RUN wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O  /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc ;\
    chsh -s /bin/zsh

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

ENV PROFILE=clang-14
RUN conan profile new ${PROFILE} --detect ;\
    ln -s ${HOME}/.conan_profiles/${PROFILE} ${HOME}/.conan_profiles/default ;\
    conan profile update settings.compiler=clang ${PROFILE} ;\
    conan profile update settings.compiler.version=14 ${PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/lib/llvm-14/bin/clang", "cpp": "/usr/lib/llvm-14/bin/clang++"}' ${PROFILE} ;\
    grep -Fx "tools.cmake.cmaketoolchain:generator=Ninja" ${HOME}/.conan/global.conf &>/dev/null || echo tools.cmake.cmaketoolchain:generator=Ninja >> ${HOME}/.conan/global.conf

ENV CC=/usr/lib/llvm-14/bin/clang
ENV CXX=/usr/lib/llvm-14/bin/clang++
ENV CONAN_DEFAULT_PROFILE_PATH=${HOME}/.conan/profiles/${PROFILE}
ENV CMAKE_CXX_COMPILER_LAUNCHER=/usr/bin/ccache
ENV CMAKE_GENERATOR=Ninja
ENV CMAKE_BUILD_TYPE=Debug
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
ENV CMAKE_C_COMPILER=${CC}
ENV CMAKE_CXX_COMPILER=${CXX}
ENV CODE_COVERAGE_GCOV_TOOL="/usr/lib/llvm-14/bin/llvm-cov gcov"

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
    'grep -A10 -B10 -E "compiler=clang|compiler=gcc" | '\
    'grep -E "compiler.version=14|compiler.version=5" >/dev/null && '\
    'echo $(readlink -f $(dirname $i)/include); '\
    'done' >> TODO.txt

RUN cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile ;\
    echo 'export CCACHE_BASEDIR=$WORK' >> ~/.zprofile ;\
    echo "alias rm-build='realpath . | grep \"^.*/\.build[^/]*$\" &>/dev/null && find -mindepth 1 -maxdepth 1 -type d | xargs rm -rf {} \; && find -mindepth 1 -maxdepth 1 -type f | xargs rm -f {} \;'" >> ~/.zprofile
