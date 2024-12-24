#!/usr/bin/env bash

base=$(dirname "$(readlink -f "$0")")

set -eu

function parse_parameters() {
    while (($#)); do
        case $1 in
            all | binutils | deps | kernel | llvm) action=$1 ;;
            *) exit 33 ;;
        esac
        shift
    done
}

function do_all() {
    do_deps
    do_llvm
    do_binutils
    do_kernel
}

function do_binutils() {
    "$base"/build-binutils.py -t x86_64
}

function do_deps() {
        [[ -z ${GITHUB_ACTIONS:-} ]] && return 0
        export TZ=Asia/Jakarta
        ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
        apt-get -y update && apt-get -y upgrade && apt-get -y install git libxml2 python3-pip default-jre tzdata
        apt-get -y install gcc llvm lld g++-multilib clang python3 python3-pip default-jre
        apt-get -y update && apt-get -y upgrade && apt-get -y install git automake lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng bc libstdc++6 libncurses5 wget python3 python3-pip gcc clang libssl-dev rsync flex git-lfs libz3-dev libz3-4 axel tar patchelf ccache help2man && \
        python3 -m pip  install networkx && \
        apt-get install -y --no-install-recommends \
        bc \
        bison \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        flex \
        gcc \
        g++ \
        git \
        libelf-dev \
        libssl-dev \
        lld \
        make \
        ninja-build \
        python3 \
        texinfo \
        xz-utils \
        zlib1g-dev 
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
}

function do_kernel() {
    cd "$base"/kernel
    ./build.sh -t X86
}

function do_llvm() {
    extra_args=()
    [[ -n ${GITHUB_ACTIONS:-} ]] && extra_args+=(--no-ccache)

    "$base"/build-llvm.py \
        --assertions \
        --branch "release/14.x" \
        --build-stage1-only \
        --check-targets clang lld llvm \
        --install-stage1-only \
        --projects "clang;lld" \
        --shallow-clone \
        --targets X86 \
        "${extra_args[@]}"
}

parse_parameters "$@"
do_"${action:=all}"
