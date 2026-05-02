#!/bin/bash
source utils/colors.sh

ENV_ROOT=~/android
TOOLCHAIN_PATH="${ENV_ROOT}/toolchain_oneplus_sm8350"

# Check for build-tools and clang repository
BUILD_TOOLS="https://android.googlesource.com/kernel/prebuilts/build-tools"
COMPILER="https://gitlab.com/kei-space/clang/r547379.git"
BUILD_TOOLS_BRANCH="main-kernel-build-2024"
COMPILER_BUILD="clang-r547379"

cecho YELLOW "[*] Checking toolchain..."

# Check for build-tools
echo "Checking build-tools: $BUILD_TOOLS"
echo "Branch: $BUILD_TOOLS_BRANCH"
if [ -d "$TOOLCHAIN_PATH/build-tools" ]; then
    cecho GREEN "✓ build-tools found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ build-tools not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    git clone --branch "$BUILD_TOOLS_BRANCH" "$BUILD_TOOLS" "$TOOLCHAIN_PATH/build-tools" || exit 1
    cecho GREEN "✓ build-tools downloaded"
fi

# Check for clang
echo "Checking clang: $COMPILER"
if [ -d "$TOOLCHAIN_PATH/$COMPILER_BUILD" ]; then
    cecho GREEN "✓ Clang found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ Clang not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    git clone "$COMPILER" "$TOOLCHAIN_PATH/$COMPILER_BUILD" || exit 1
    cecho GREEN "✓ Clang downloaded"
fi

# Check for payload-dumper-go
PAYLOAD_DUMPER_REPO="ssut/payload-dumper-go"
PAYLOAD_DUMPER_PATH="$TOOLCHAIN_PATH/payload-dumper-go"
PAYLOAD_DUMPER_BINARY="payload-dumper-go"

echo "Checking payload-dumper-go: https://github.com/$PAYLOAD_DUMPER_REPO"
if [ -d "$PAYLOAD_DUMPER_PATH" ]; then
    cecho GREEN "✓ payload-dumper-go found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ payload-dumper-go not found in $TOOLCHAIN_PATH, downloading latest release..."
    mkdir -p "$TOOLCHAIN_PATH"
    LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/$PAYLOAD_DUMPER_REPO/releases/latest | grep "browser_download_url.*linux_amd64" | head -1 | cut -d '"' -f 4)
    if [ -z "$LATEST_RELEASE_URL" ]; then
        echo "✗ Failed to find latest release URL"
        exit 1
    fi
    curl -L "$LATEST_RELEASE_URL" -o $PAYLOAD_DUMPER_PATH.tar.gz || exit 1
    mkdir -p $PAYLOAD_DUMPER_PATH
    tar -xzvf $PAYLOAD_DUMPER_PATH.tar.gz -C $PAYLOAD_DUMPER_PATH
    chmod +x "$PAYLOAD_DUMPER_PATH"/$PAYLOAD_DUMPER_BINARY
    rm $PAYLOAD_DUMPER_PATH.tar.gz
    cecho GREEN "✓ payload-dumper-go downloaded"
fi

AK3_REPO="https://github.com/Gamesmes90/anykernel3-oneplus-sm8350"
AK3_REPO_PATH="$TOOLCHAIN_PATH/anykernel3-oneplus-sm8350"
AK3_BRANCH="lemonade"
echo "Checking anykernel3-oneplus-sm8350: $AK3_REPO"
if [ -d $AK3_REPO_PATH ]; then
    cecho GREEN "✓ anykernel3-oneplus-sm8350 found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ anykernel3-oneplus-sm8350 not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    git clone --branch "$AK3_BRANCH" "$AK3_REPO" "$TOOLCHAIN_PATH/anykernel3-oneplus-sm8350" || exit 1
    cecho GREEN "✓ anykernel3-oneplus-sm8350 downloaded"
fi
