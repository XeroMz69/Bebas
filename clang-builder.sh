#!/usr/bin/env bash
WORKDIR="$(pwd)"
mkdir -p $WORKDIR/out
# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

export GIT_SSL_NO_VERIFY=1
git config --global http.sslverify false

# Set a directory
DIR="$(pwd ...)"
EsOne="${1}"
CheckDuplicate="${2}"
fail="n"
TagsDate="$(date +"%Y%m%d")"
TagsDateF="$(date +"%Y%m%d")"
ccache -M 10G

# unlimitedEcho(){
#     StATS=1
#     while [ ! -f $DIR/stop-spam-echo.txt ];
#     do
#         msg ">> processing . . . <<"
#         sleep 10s
#     done
# }

EXTRA_ARGS=()
EXTRA_PRJ=""
UseBranch=""

for ListBranch in 10 11 12 13 14 15 16 main
do
    if [[ "$ListBranch" == "$EsOne" ]];then
        if [[ "$ListBranch" == "main" ]];then
            UseBranch="main"
        else
            UseBranch="release/$EsOne.x"
        fi
    fi
done


if [[ -z "$UseBranch" ]];then
    msg "branch not found"
    exit
fi

# if [ "$EsOne" == "13" ];then
#     UseBranch="release/13.x"
# elif [ "$EsOne" == "14" ];then
#     # EXTRA_ARGS+=("--bolt")
#     # EXTRA_PRJ=";bolt"
#     UseBranch="release/14.x"
# elif [ "$EsOne" == "main" ];then
#     # EXTRA_ARGS+=("--bolt")
#     # EXTRA_PRJ=";bolt"
#     UseBranch="main"
# else
#     msg "huh ???"
#     exit
# fi

# AddBolt() {
#     EXTRA_ARGS+=("--bolt")
#     EXTRA_PRJ=";bolt"
# }

# if [[ "$EsOne" != "main"  ]] && [[ "$EsOne" -gt "13"  ]];then
#     AddBolt
# elif [[ "$EsOne" == "main"  ]];then
#     AddBolt
# fi

# if [[ "$UseBranch" != "main" ]] && [[ "$(date +"%u")" != "1" ]];then
#     # Stop="Y"
#     msg "for $UseBranch, only can be compiled on monday"
#     exit
# fi

TomTal=$(nproc)
TomTal=$(($TomTal+1))
# unlimitedEcho &
# EXTRA_ARGS+=("--pgo kernel-defconfig")
# --targets "AArch64;ARM;X86" \
# --pgo "kernel-defconfig-slim" \
msg "projects : clang;compiler-rt;lld;polly;openmp${EXTRA_PRJ}"
./build-llvm.py \
    --clang-vendor "Xero" \
    --targets "AArch64;ARM;X86" \
    --defines "LLVM_PARALLEL_COMPILE_JOBS=$TomTal LLVM_PARALLEL_LINK_JOBS=$TomTal CMAKE_C_FLAGS='-g0 -O3' CMAKE_CXX_FLAGS='-g0 -O3' LLVM_USE_LINKER=lld LLVM_ENABLE_LLD=ON" \
    --shallow-clone \
    --branch "$UseBranch" \
    --projects "clang;compiler-rt;lld;polly;openmp${EXTRA_PRJ}" \
    --no-ccache \
    --quiet-cmake \
    ${EXTRA_ARGS[@]} || fail="y"

# echo "idk" > $DIR/stop-spam-echo.txt

if [[ "$fail" == "n" ]];then
    $DIR/install/bin/clang --version

    # Build binutils --targets aarch64 arm x86_64
    ./build-binutils.py --targets aarch64 arm x86_64
    # Remove unused products
    # rm -f $DIR/install/lib/*.a $DIR/install/lib/*.la $DIR/install/lib/clang/*/lib/linux/*.a*
    # IFS=$'\n'
    # for f in $(find $DIR/install -type f -exec file {} \;); do
    #     if [ -n "$(echo $f | grep 'ELF .* interpreter')" ]; then
    #         i=$(echo $f | awk '{print $1}'); i=${i: : -1}
    #         # Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
    #         patchelf --set-rpath "$DIR/install/lib" "$i"
    #         msg "patchelf --set-rpath '$DIR/install/lib' '$i'"
    #         # Strip remaining products
    #         if [ -n "$(echo $f | grep 'not stripped')" ]; then
    #             strip --strip-unneeded "$i"
    #             msg "strip --strip-unneeded '$i'"
    #         fi
    #     elif [ -n "$(echo $f | grep 'ELF .* relocatable')" ]; then
    #         if [ -n "$(echo $f | grep 'not stripped')" ]; then
    #             i=$(echo $f | awk '{print $1}');
    #             strip --strip-unneeded "${i: : -1}"
    #             msg "strip --strip-unneeded '${i: : -1}'"
    #         fi
    #     else
    #         if [ -n "$(echo $f | grep 'not stripped')" ]; then
    #             i=$(echo $f | awk '{print $1}');
    #             strip --strip-all "${i: : -1}"
    #             msg "strip --strip-all '${i: : -1}'"
    #         fi
    #     fi
    # done

    # Remove unused products
    rm -fr $DIR/install/include
    rm -f $DIR/install/lib/*.a $DIR/install/lib/*.la

    # Strip remaining products
    for f in $(find $DIR/install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
        strip -s "${f: : -1}"
    done

    # Set executable rpaths so setting LD_LIBRARY_PATH isn't necessary
    for bin in $(find $DIR/install -mindepth 2 -maxdepth 3 -type f -exec file {} \; | grep 'ELF .* interpreter' | awk '{print $1}'); do
        # Remove last character from file output (':')
        bin="${bin: : -1}"

        echo "$bin"
        patchelf --set-rpath "$DIR/install/lib" "$bin"
    done

    # Release Info
    pushd llvm-project || exit
    llvm_commit="$(git rev-parse HEAD)"
    short_llvm_commit="$(cut -c-8 <<< "$llvm_commit")"
    popd || exit

    llvm_commit_url="https://github.com/llvm/llvm-project/commit/$short_llvm_commit"
    binutils_ver="$(ls | grep "^binutils-" | sed "s/binutils-//g")"
    clang_version="$($DIR/install/bin/clang --version | head -n1 | cut -d' ' -f4)"
    clang_version_f="$($DIR/install/bin/clang --version | head -n1)"

    git config --global user.name 'XeroMz69'
    git config --global user.email 'adamyd18@gmail.com'

    ZipName="Xero-Clang-$clang_version-${TagsDate}.tar.gz"
    ClangLink="https://github.com/XeroMz69/Clang/releases/download/Xero-Clang-20.0.0-$(date +"%Y%m%d")/$ZipName"

    pushd $DIR/install || exit
    echo "# Quick Info" > README.md
    echo "* Build Date : $TagsDateF" >> README.md
    echo "* Clang Version : $clang_version_f" >> README.md
    echo "* Binutils Version : $binutils_ver" >> README.md
    echo "* Compiled Based : $llvm_commit_url" >> README.md
    echo "" >> README.md
    echo "# link downloads:" >> readme.md
    echo "* <a href=$ClangLink>$ZipName</a>" >> readme.md
    tar -czvf ../"$ZipName" *
    mv ../"$ZipName" $WORKDIR/out/.
    mv README.md $WORKDIR/out/.
    git clone https://${GIT_SECRET_MAIN}@github.com/XeroMz69/Clang.git -b main $WORKDIR/Clang
    mv * $WORKDIR/Clang/.
    cp -f $WORKDIR/out/README.md $WORKDIR/.
    cd $WORKDIR/Clang
    git config --global user.name 'XeroMz69'
    git config --global user.email 'adamyd18@gmail.com'
    git lfs install
    git lfs track libclang-cpp.so.20.0git
    git lfs track bin/clang-repl
    git add .
    git commit -sm "$(date +"%Y%m%d")" -m "$(cat $WORKDIR/README.md)"
    git push --all origin -f
    cd $WORKDIR
    cd out
    popd || exit

    chmod +x github-release
    ./github-release release \
            --security-token "$GIT_SECRET_MAIN" \
            --user XeroMz69 \
            --repo Clang \
            --tag Xero-Clang-20.0.0-$(date +"%Y%m%d") \
            --description "$(cat out/README.md)"
    
    ./github-release upload \
             --security-token "$GIT_SECRET_MAIN" \
             --user XeroMz69 \
             --repo Clang \
             --tag Xero-Clang-20.0.0-$(date +"%Y%m%d") \
             --name "$ZipName" \
             --file "out/"$ZipName"" || fail="y"

fi
