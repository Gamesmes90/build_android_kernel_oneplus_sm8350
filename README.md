# Kernel build environment for OnePlus SM8350 Kernel
This repository uses various scripts to create a building environment for the [OnePlus SM8350 kernel tree](https://github.com/Gamesmes90/android_kernel_oneplus_sm8350).

### Requirements
- A linux distro 
- Git
- A Lineage OS ROM flashable zip, needed to build a working vendor_dlkm.img
- A oneplus-sm8350 kernel tree

## Getting Started
- Download the kernel source in the root of this repository
    - The default name for the kernel source tree is ``android_kernel_oneplus_sm8350``
    ```
    git clone [your-kernel-repo] android_kernel_oneplus_sm8350
    ```
- Download a lineage os build and place it in the root of this repository
    - This will be used to extract the ``vendor_dlkm.img`` which will be used as a base for the ``vendor_dlkm.img`` of the kernel being built
- Run [build.sh](./build.sh)
    ```
    ./build.sh
    ```
    - This will automatically build and package the kernel in an ak3 zip

### Output
Final build files will be written in ``build`` folder.
The environment produces the following
- ``Image``
    - Kernel image
- ``vendord_dlkm.img``
    - vendord_dlkm partition
- ``modules``
    - Folder containing vendor_ramdisk modules
- ``kernel-oneplus-sm8350.zip``
    - AnyKernel3 flashable zip of the kernel

## Scripts Overview
### [Build.sh](build.sh)
Main script. Contains all possibile commands.
#### Commands list
- ``toolchain_setup``
    - Checks and sets up the toolchain
    - Implemented in [toolchain_setup.sh](./scripts/toolchain_setup.sh)
- ``kernel``
    - Builds the kernel
    - Implemented in [build_kernel.sh](./scripts/build_kernel.sh)
- ``kernel_clean``
    - Runs ``make clean`` and ``make mrproper`` on the kernel source tree
    - Implemented in [build_kernel.sh](./scripts/build_kernel.sh)
- ``vendor``
    - Builds vendro_dlkm.img and ramdisk modules
    - Implemented in [vendor.sh](./scripts/vendor.sh)
- ``ak3``
    - Packages the kernel with anykernel3
    - See [ak3.sh](./scripts/ak3.sh) for details.
- ``lemonade``
    - Downloads the latest Lineage OS ROM for OnePlus 9
    - See [lineage.sh](./utils/lineage.sh) for details.
- ``lemonadep``
    - Downloads the latest Lineage OS ROM for OnePlus 9 Pro
    - See [lineage.sh](./utils/lineage.sh) for details.
- ``clean``
    - Cleans all build artifacts
    - Implemented in [build.sh](build.sh)

### Utils scripts
These scripts are used by the main scripts for various utility functions
- [colors.sh](./utils/colors.sh)
    - Has ``cecho`` function for colored output
- [extract_vendor_dlkm.sh](./utils/extract_vendor_dlkm.sh)
    - Extracts the ``vendor_dlkm.img`` from the provided Lineage OS zip file
- [set_env.sh](./utils/set_env.sh)
    - Exports to ``PATH`` the locations of toolchain utilities
- [lineage.sh](./utils/lineage.sh)
    - Downloads the latest Lineage OS rom for the specified device

## Toolchain
The toolchain is installed in ``~/android/toolchain_oneplus_sm8350`` and has the following tools
- [build-tools](https://android.googlesource.com/kernel/prebuilts/build-tools)
    - Repository: https://android.googlesource.com/kernel/prebuilts/build-tools
    - Branch: [main-kernel-build-2024](https://android.googlesource.com/kernel/prebuilts/build-tools/+/refs/heads/main-kernel-build-2024)
    - Contains various tools for building android images
    - Mainly used for mkfs.erofs implementation
- [clang-r547379](https://gitlab.com/kei-space/clang/r547379.git)
    - Repository: https://gitlab.com/kei-space/clang/r547379.git
    - Version: 20.0.0
    - Main compiler
    - Compiled from [this revision](https://android.googlesource.com/toolchain/llvm-project/+/b718bcaf8c198c82f3021447d943401e3ab5bd54)
    - This repository is a mirror of [the prebuilt from google](https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/)
        - This is used instead of google's repository because the google one contains various other clang versions not needed that make the download size unnecessarily big
- [payload-dumper-go](https://github.com/ssut/payload-dumper-go)
    - Repository: https://github.com/ssut/payload-dumper-go
    - Version: latest
    - This tool is used to extract the payload.bin file from the Lineage OS zip
- [anykernel3-oneplus-sm8350](https://github.com/Gamesmes90/anykernel3-oneplus-sm8350)
    - Repository: https://github.com/Gamesmes90/anykernel3-oneplus-sm8350
    - Branch: [lemonade](https://github.com/Gamesmes90/anykernel3-oneplus-sm8350/tree/lemonade)
    - AnyKernel3 Zip Template customized for lemonade/lemonadep devices 

### Notes
To get a kernel up and running on lemonade/lemonadep, all the modules built with the kernel need to be added in ``vendor_dlkm.img`` and a specific set of modules have to be put in ``vendor_ramdisk`` and then these have to be flashed with the kernel.

This repository uses a [custom AnyKernel3 repo](https://github.com/Gamesmes90/anykernel3-oneplus-sm8350) to achieve this.

In addition, the AnyKernel3 repo has a small [kernelsu module](https://github.com/Gamesmes90/anykernel3-oneplus-sm8350/tree/lemonade/ksu_module) that runs some kernel tweaks at boot, it is configurable.

#### Modules in ``vendor_ramdisk/lib/modules``
- msm_drm.ko 
- apr_dlkm.ko
- q6_pdr_dlkm.ko
- q6_notifier_dlkm.ko
- adsp_loader_dlkm.ko
- snd_event_dlkm.ko

An alternative to this would be to build the kernel with all the modules as built-in.

##### vendor_dlkm.img
Using a base image is necessary to build a ``vendor_dlkm.img``, as the image contains other files that are not generated by just building the kernel (e.g. ``/etc/build.prop`` generated by the lineage build system). This approach is also easier as it allows to drop-in replacement/new modules in the extracted base image and swiftly generate the erofs image.
