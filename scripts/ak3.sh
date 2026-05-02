#!/bin/bash
source utils/colors.sh

set -euo pipefail

FILENAME=kernel-oneplus-sm8350

cecho YELLOW "[*] Building AnyKernel3 flashable zip..."

mkdir -p temp/ak3-staging

cp -r ~/android/toolchain_oneplus_sm8350/anykernel3-oneplus-sm8350/* temp/ak3-staging

# Copy files
cp build/Image temp/ak3-staging
cp build/vendor_dlkm.img temp/ak3-staging
cp -r build/modules temp/ak3-staging/vendor_ramdisk/lib

pushd temp/ak3-staging > /dev/null
# Clean build the zip file
if [ -d ../build/$FILENAME.zip ]; then
    rm ../build/$FILENAME.zip
fi

# Zip folder
zip -r9 ../../build/$FILENAME.zip * -x .git README.md *placeholder
cecho GREEN "[✓] Flashable zip created."
popd > /dev/null
