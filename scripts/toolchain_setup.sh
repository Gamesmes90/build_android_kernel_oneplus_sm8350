#!/bin/bash
source utils/colors.sh
# Toolchain variables
. utils/toolchain_env.sh

check_updates () {
    cd $1
    cecho YELLOW "[*] Checking $2 for updates"
    if git pull; then
        cd $SCRIPT_DIR && cd ..
        cecho GREEN "✓ $2 is up to date"
    else
        echo "✗ Failed to update $2"
        exit 1
    fi
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# Check toolchain
cecho YELLOW "[*] Checking toolchain..."

# Check for build-tools
echo "Checking build-tools: $BUILD_TOOLS"
echo "Branch: $BUILD_TOOLS_BRANCH"
if [ -d $BUILD_TOOLS_PATH ]; then
    cecho GREEN "✓ build-tools found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ build-tools not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    mkdir $BUILD_TOOLS_PATH && curl -L  $BUILD_TOOLS | tar xz --warning=no-timestamp -C $BUILD_TOOLS_PATH
    cecho GREEN "✓ build-tools downloaded"
fi

# Check for clang
echo "Checking clang: $COMPILER"
if [ -d $COMPILER_PATH ]; then
    cecho GREEN "✓ Clang found in $TOOLCHAIN_PATH"
else
    cecho RED "✗ Clang not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    mkdir $COMPILER_PATH && curl -L $COMPILER | tar xz --warning=no-timestamp -C $COMPILER_PATH || exit 1
    cecho GREEN "✓ Clang downloaded"
fi

# Check for payload-dumper-go
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

# Check for anykernel3
echo "Checking anykernel3-oneplus-sm8350: $AK3_REPO"
if [ -d $AK3_REPO_PATH ]; then
    cecho GREEN "✓ anykernel3-oneplus-sm8350 found in $TOOLCHAIN_PATH"
    check_updates $AK3_REPO_PATH "anykernel3"
else
    cecho RED "✗ anykernel3-oneplus-sm8350 not found in $TOOLCHAIN_PATH, downloading..."
    mkdir -p "$TOOLCHAIN_PATH"
    git clone --branch "$AK3_BRANCH" "$AK3_REPO" "$AK3_REPO_PATH" || exit 1
    cecho GREEN "✓ anykernel3-oneplus-sm8350 downloaded"
fi

# Inject Kernel tag into ksu module
source .github/workflows/versioning
sed -i "s|KERNEL_TAG=.*|KERNEL_TAG=$VERSION-$ANDROID_VERSION-$DATE|g" $AK3_REPO_PATH/ksu_module/action.sh