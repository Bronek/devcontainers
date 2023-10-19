ARG DIST_TAG=22.04
FROM ubuntu:$DIST_TAG

WORKDIR /root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update ;\
    apt-get install -y --install-recommends \
    lsb-release vim wget curl git grep sed gdb zsh cmake ninja-build \
    clang-tools-15 clang-tidy-15 clangd-15 llvm-15 \
    clang-13 clang-14 clang-15 \
    clang-format-11 clang-format-12 clang-format-13 clang-format-14 clang-format-15 \
    python3 python3-pip python3-venv ;\
    apt-get clean

ENV PATH=${PATH}:/usr/lib/llvm-15/bin:/usr/lib/llvm-11/bin

RUN wget -O /etc/zsh/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc ;\
    wget -O  /etc/zsh/newuser.zshrc.recommended  https://git.grml.org/f/grml-etc-core/etc/skel/.zshrc

RUN apt-get update ;\
    apt-get install -y --install-recommends \
    g++-12 libstdc++-12-dev ;\
    apt-get clean

ARG USER_NAME
ARG USER_UID
ARG USER_GID
RUN (groupadd --gid ${USER_GID} ${USER_NAME} || groupmod -n ${USER_NAME} $(getent group ${USER_GID} | cut -d: -f1)) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USER_NAME} -s /bin/zsh -d /home/${USER_NAME}

ARG WORKSPACE
RUN mkdir -p ${WORKSPACE} ;\
    chown ${USER_NAME}:${USER_NAME} ${WORKSPACE}

ENV HOSTALIASES /home/${USER_NAME}/hosts
RUN cp /etc/hosts /home/${USER_NAME}/hosts ;\
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/hosts

USER ${USER_NAME}
ENV HOME=/home/${USER_NAME}
WORKDIR ${HOME}

ENV VIRTUAL_ENV=${HOME}/venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH=${VIRTUAL_ENV}/bin:${PATH}
ENV EDITOR=vim
ENV VISUAL=vim

RUN pip --no-cache-dir install 'conan<2'

ENV CONAN_PROFILE=gcc-12
RUN conan profile new ${CONAN_PROFILE} --detect ;\
    conan profile update settings.compiler=gcc ${CONAN_PROFILE} ;\
    conan profile update settings.compiler.version=12 ${CONAN_PROFILE} ;\
    conan profile update settings.compiler.cppstd=20 ${CONAN_PROFILE} ;\
    conan profile update settings.compiler.libcxx=libstdc++11 ${CONAN_PROFILE} ;\
    conan profile update 'conf.tools.build:compiler_executables={"c": "/usr/bin/gcc-12", "cpp": "/usr/bin/g++-12"}' ${CONAN_PROFILE} ;\
    ln -s ${HOME}/.conan/profiles/${CONAN_PROFILE} ${HOME}/.conan/profiles/default

ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV WORKSPACE=${WORKSPACE}

RUN echo "mkdir .build" > TODO.txt ;\
    echo "ln -s .build/compile_commands.json compile_commands.json" >> TODO.txt ;\
    echo "cd .build" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Debug" >> TODO.txt ;\
    echo "conan install .. --output-folder . --build missing --settings build_type=Release" >> TODO.txt ;\
    echo "cmake -DCMAKE_GENERATOR='Ninja Multi-Config' -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_TOOLCHAIN_FILE:FILEPATH=build/generators/conan_toolchain.cmake .." >> TODO.txt ;\
    echo "cmake --build . --config Release" >> TODO.txt ;\
    echo "cmake --build . --config Debug" >> TODO.txt

RUN cp /etc/zsh/newuser.zshrc.recommended .zshrc ;\
    touch .zshrc.local ;\
    ln -s .profile .zprofile
