#!/bin/bash
source utils/colors.sh

set -euo pipefail

clean(){
    make "${MAKEFLAGS[@]}" clean
    make "${MAKEFLAGS[@]}" mrproper
}

KERNEL_FOLDER="android_kernel_oneplus_sm8350"

if [ ! -d "$KERNEL_FOLDER" ]; then
    cecho RED "Missing kernel source tree!"
    exit 1
fi

. utils/set_env.sh

DEFCONFIG="vendor/lahaina-qgki_defconfig"

MAKEFLAGS=(
    O=out 
    ARCH=arm64 
    LLVM=1 
    CC=clang 
    LD=ld.lld 
    AR=llvm-ar 
    NM=llvm-nm 
    OBJCOPY=llvm-objcopy 
    OBJDUMP=llvm-objdump 
    READELF=llvm-readelf 
    OBJSIZE=llvm-size 
    STRIP=llvm-strip 
    CROSS_COMPILE=aarch64-linux-gnu- 
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-
)

cecho YELLOW "[*] Building the kernel..."

pushd "$KERNEL_FOLDER" > /dev/null
if [ "${1:-}" = "clean" ]; then
    if [ -d "drivers/kernelsu" ]; then
        sed -i 's/^[[:space:]]*obj-\$(CONFIG_KSU)[[:space:]]*+=[[:space:]]*kernelsu\//#&/' drivers/Makefile
        clean
        sed -i 's/^#[[:space:]]*\(obj-\$(CONFIG_KSU)[[:space:]]*+=[[:space:]]*kernelsu\/\)/\1/' drivers/Makefile
    else
        clean
    fi
else
    # Generate configuration from defconfig file
    make "${MAKEFLAGS[@]}" $DEFCONFIG
    # Compile
    make -j$(nproc) "${MAKEFLAGS[@]}"
    # Install stripped modules
    make "${MAKEFLAGS[@]}" INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install
    # Copy kernel image into build folder
    mkdir -p ../build/
    cp out/arch/arm64/boot/Image ../build/
    cecho GREEN "[✓] Build completed."
fi
popd > /dev/null

