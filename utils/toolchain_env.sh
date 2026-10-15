#!/bin/bash

# toolchain Path
ENV_ROOT=~/android
TOOLCHAIN_PATH="${ENV_ROOT}/toolchain_oneplus_sm8350"

# build-tools
BUILD_TOOLS_BRANCH="main-kernel-2026"
BUILD_TOOLS="https://android.googlesource.com/kernel/prebuilts/build-tools/+archive/refs/heads/$BUILD_TOOLS_BRANCH.tar.gz"
BUILD_TOOLS_PATH=$TOOLCHAIN_PATH/build-tools

BUILD_TOOLS_BIN=linux_musl-x86/bin/

# clang
CLANG_BUILD=r596125

COMPILER_TAG="android-security-17.0.0_r2"
COMPILER_BUILD="clang-$CLANG_BUILD"
COMPILER="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/$COMPILER_TAG/$COMPILER_BUILD.tar.gz"
COMPILER_PATH=$TOOLCHAIN_PATH/$COMPILER_BUILD

# payload-dumper-go
PAYLOAD_DUMPER_REPO="ssut/payload-dumper-go"
PAYLOAD_DUMPER_PATH="$TOOLCHAIN_PATH/payload-dumper-go"
PAYLOAD_DUMPER_BINARY="payload-dumper-go"

# anykernel3
AK3_REPO="https://github.com/Gamesmes90/anykernel3-oneplus-sm8350"
AK3_REPO_PATH="$TOOLCHAIN_PATH/anykernel3-oneplus-sm8350"
AK3_BRANCH="lemonade"