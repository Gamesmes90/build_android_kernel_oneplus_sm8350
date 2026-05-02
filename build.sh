#!/bin/bash
source utils/colors.sh

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
    echo GREEN "Removing build files..."
    rm -rf temp/
    rm vendor_dlkm.img
    . scripts/build_kernel.sh clean
    echo GREEN "Build files removed."
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
                echo "  clean                           - Remove the build files"
                echo ""
                echo "If no arguments are provided, all functions are run in order."
                echo "Use 'help', '-h', or '--help' to show this message."
                ;;
            *)
                cecho RED "Unknown function: $arg"
                echo "Available functions: toolchain_setup, build_kernel, build_vendor_dlkm, build_vendor_ramdisk_modules, build_ak3_zip, clean"
                echo "Use '$0 help' for more information."
                exit 1
                ;;
        esac
    done
fi

