#!/bin/bash
source utils/colors.sh
set -euo pipefail

toolchain_setup() {
    . scripts/toolchain_setup.sh
}

kernel() {
    . scripts/build_kernel.sh
}

vendor() {
    . scripts/vendor.sh
}

ak3() {
    . scripts/ak3.sh
}

clean() {
    cecho YELLOW "Removing build files..."
    rm -rf temp/
    rm -rf build/
    . scripts/build_kernel.sh clean
    rm -rf android_kernel_oneplus_sm8350/out
    cecho GREEN "Build files removed."
}

if [ $# -eq 0 ]; then
    toolchain_setup
    kernel
    vendor
    ak3
else
    for arg in "$@"; do
        case "$arg" in
            toolchain_setup)
                toolchain_setup
                ;;
            kernel)
                kernel
                ;;
            kernel_clean)
                . scripts/build_kernel.sh clean
                ;;
            vendor)
                vendor
                ;;
            ak3)
                ak3
                ;;
            lemonade)
                . utils/lineage.sh lemonade
                ;;
            lemonadep)
                . utils/lineage.sh lemonadep
                ;;
            
            clean)
                clean
                ;;
            help|-h|--help)
                echo "Usage: $0 [function_name ...]"
                echo ""
                echo "Available functions:"
                echo "  toolchain_setup                 - Set up the toolchain"
                echo "  kernel                          - Build the kernel"
                echo "  kernel_clean                    - Clean kernel build files"
                echo "  vendor                          - Build vendor_dlkm.img and vendor ramdisk modules"
                echo "  ak3                             - Build AnyKernel3 zip"
                echo "  lemonade                        - Download latest Lineage OS ROM for OnePlus 9"
                echo "  lemonadep                       - Download latest Lineage OS ROM for OnePlus 9 Pro"
                echo "  clean                           - Remove the build files"      
                echo ""
                echo "If no arguments are provided, all functions are run in order."
                echo "Use 'help', '-h', or '--help' to show this message."
                ;;
            *)
                cecho RED "Unknown function: $arg"
                echo "Available functions: toolchain_setup, kernel, kernel_clean, vendor, ak3, lemonade, lemonadep, clean"
                echo "Use '$0 help' for more information."
                exit 1
                ;;
        esac
    done
fi

