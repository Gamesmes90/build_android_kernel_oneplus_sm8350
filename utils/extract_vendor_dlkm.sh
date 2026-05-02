#!/bin/bash
source utils/colors.sh

set -euo pipefail

if [ -f temp/vendor_dlkm.img ]; then
    cecho GREEN "vendor_dlkm.img already exists. Skipping..."
    exit 0
fi

if [ ! -f temp/payload.bin ]; then
    echo "Extracting payload.bin from zip..."
    if [ ! -f lineage-*.*-*-nightly-*-signed.zip ]; then
        cecho RED "Lineage ROM zip not found! Please add it to the root of this directory"
        exit 1
    fi
    unzip lineage-*.*-*-nightly-*-signed.zip "payload.bin" -d temp/
    cecho GREEN "Extraction complete."
fi

. utils/set_env.sh

echo "Extracting vendor_dlkm partition..."
payload-dumper-go -o temp/ -partitions vendor_dlkm temp/payload.bin 
cecho GREEN "Extraction complete."