ARG DIST_TAG=39
FROM fedora:$DIST_TAG

WORKDIR /root

RUN dnf -y update ;\
    dnf -y install redhat-lsb python3.11 gcc \
    vim wget sudo curl git grep sed gdb zsh cmake ninja-build \
    clang clang-tools-extra llvm mold;\
    dnf -y clean all

RUN wget -O /etc/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O /etc/skel/.zshrc  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc

ARG USER_NAME
ARG USER_UID
ARG USER_GID
RUN (groupadd --gid ${USER_GID} ${USER_NAME} || groupmod -n ${USER_NAME} $(getent group ${USER_GID} | cut -d: -f1)) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/zsh -d /home/${USER_NAME} ${USER_NAME} ;\
    echo "${USER_NAME} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME}

ENV HOSTALIASES /home/${USER_NAME}/hosts
RUN cp /etc/hosts /home/${USER_NAME}/hosts || touch /home/${USER_NAME}/hosts ;\
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/hosts
RUN mkdir -p /run/host-services ;\
    chown ${USER_NAME}:${USER_NAME} /run/host-services

USER ${USER_NAME}
ENV HOME=/home/${USER_NAME}
WORKDIR ${HOME}

ENV VIRTUAL_ENV=${HOME}/venv
RUN python3.11 -m venv ${VIRTUAL_ENV}
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV EDITOR=vim
ENV VISUAL=vim

RUN mkdir -p ${HOME}/.conan_profiles ;\
    mkdir -p ${HOME}/.conan ;\
    ln -s ${HOME}/.conan_profiles ${HOME}/.conan/profiles ;\
    pip --no-cache-dir install 'conan<2'

# Fail build if unexpected clang version
RUN clang --version | grep -E "^clang version 17"

ENV PROFILE=clang-17
RUN conan profile new ${PROFILE} --detect ;\
    ln -s ${HOME}/.conan_profiles/${PROFILE} ${HOME}/.conan_profiles/default ;\
    conan profile update settings.compiler=clang ${PROFILE} ;\
    conan profile update settings.compiler.version=17 ${PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/bin/clang", "cpp": "/usr/bin/clang++"}' ${PROFILE} ;\
    grep -Fx "tools.cmake.cmaketoolchain:generator=Ninja" ${HOME}/.conan/global.conf &>/dev/null || echo tools.cmake.cmaketoolchain:generator=Ninja >> ${HOME}/.conan/global.conf

ENV CC=/usr/bin/clang
ENV CXX=/usr/bin/clang++
ENV CONAN_DEFAULT_PROFILE_PATH=${HOME}/.conan/profiles/${PROFILE}
ENV CMAKE_GENERATOR='Ninja Multi-Config'
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
ENV CMAKE_C_COMPILER=${CC}
ENV CMAKE_CXX_COMPILER=${CXX}

RUN echo "mkdir .build" > TODO.txt ;\
    echo "ln -s .build/compile_commands.json compile_commands.json" >> TODO.txt ;\
    echo "cd .build" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Debug" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Release" >> TODO.txt ;\
    echo "cmake -DCMAKE_TOOLCHAIN_FILE:FILEPATH=build/generators/conan_toolchain.cmake .." >> TODO.txt ;\
    echo "cmake --build . --config Release" >> TODO.txt ;\
    echo "cmake --build . --config Debug" >> TODO.txt ;\
    echo 'for i in $(ls ~/.conan/data/*/*/_/_/package/*/conaninfo.txt); '\
    'do head -20 $i | '\
    'grep -A10 -B10 build_type=Release | '\
    'grep -A10 -B10 os=Linux | '\
    'grep -A10 -B10 -E "^compiler=clang|^compiler=gcc" | '\
    'grep -E "^compiler.version=17|^compiler.version=5" >/dev/null && '\
    'echo $(readlink -f $(dirname $i)/include); '\
    'done' >> TODO.txt

RUN touch .zshrc.local
