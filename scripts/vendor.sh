#!/bin/bash
# vendor.sh — Generate vendor_dlkm.img for lemonade/lemondaep
# Adapted from YAKB/main.sh for OnePlus 9 / SM8350
# Adapted from Telegram user @Varakumar/gen_vendor_dlkm.sh
#
# Each run creates temp/vendor_dlkm_files
# containing extracted files.
# The vendor_dlkm.img file is in build/

# Source color output
source utils/colors.sh

set -euo pipefail

# Check for base vendor_dlkm.img
cecho YELLOW "[*] Checking for base vendor_dlkm.img..."
if ! bash utils/extract_vendor_dlkm.sh; then
    cecho "Cannot get base vendor_dlkm.img"
    exit 1
fi

# Configuration
. utils/set_env.sh

RUN_DIR="temp/vendor_dlkm_files"
OUT_DIR="build"
BASE_IMG="temp/vendor_dlkm.img"
KDIR="android_kernel_oneplus_sm8350"
BUILD_MODULES_DIR="${KDIR}/out/modules"

# Check for working directory
if [ -d ${RUN_DIR} ]; then
    cecho YELLOW "Found working directory. Cleaning..."
    rm -rf ${RUN_DIR} 
fi
# Create working directory
mkdir -p "${RUN_DIR}"
cecho YELLOW "[*] Output directory: ${OUT_DIR}"

# Extract base vendor_dlkm.img
EXTRACT_DIR="${RUN_DIR}/extracted"
mkdir -p "${EXTRACT_DIR}"

cecho YELLOW "[*] Extracting base vendor_dlkm.img..."
fsck.erofs --extract="${EXTRACT_DIR}" --overwrite "${BASE_IMG}" 2>&1
cecho GREEN "[✓] Extracted base image"

MODULES_DIR="${EXTRACT_DIR}/lib/modules"

BASE_KO_COUNT=$(find "${MODULES_DIR}" -name "*.ko" | wc -l)
cecho YELLOW "    Base has ${BASE_KO_COUNT} modules"

# Derive exclude set from base before replacing modules
# Base -> total .ko
# Base modules.load
declare -A BASE_LOAD_SET
while IFS= read -r entry; do
    [ -z "${entry}" ] && continue
    BASE_LOAD_SET["${entry}"]=1
done < "${MODULES_DIR}/modules.load"

# Base blocklist = modules that should never load
declare -A BLOCKLIST_SET
if [ -f "${MODULES_DIR}/modules.blocklist" ]; then
    while read -r _ mod; do
        [ -n "${mod}" ] && BLOCKLIST_SET["${mod}"]=1
    done < <(grep '^blocklist ' "${MODULES_DIR}/modules.blocklist" || true)
fi

# Exclude set = modules that aren't in modules.load and modules.blocklist
declare -A EXCLUDE_SET
for ko in "${MODULES_DIR}"/*.ko; do
    mod_name=$(basename "${ko}" .ko)
    if [ -z "${BASE_LOAD_SET[${mod_name}]+x}" ] && [ -z "${BLOCKLIST_SET[${mod_name}]+x}" ]; then
        EXCLUDE_SET["${mod_name}"]=1
    fi
done

cecho YELLOW "    Derived ${#EXCLUDE_SET[@]} excluded modules: ${!EXCLUDE_SET[*]}"

# Validate build output
if [ ! -d "${BUILD_MODULES_DIR}" ]; then
    cecho LIGHT_RED "[✗] No modules_install output at ${BUILD_MODULES_DIR}"
    echo "    Run: make O=out ... INSTALL_MOD_PATH=out/modules modules_install"
    exit 1
fi

BUILD_KO_COUNT=$(find "${BUILD_MODULES_DIR}" -type f -name "*.ko" | wc -l)
if [ "${BUILD_KO_COUNT}" -eq 0 ]; then
    cecho LIGHT_RED "[✗] No .ko files found in ${BUILD_MODULES_DIR}"
    exit 1
fi

cecho YELLOW "[*] Found ${BUILD_KO_COUNT} built modules"

# Replace base modules with built ones
cecho YELLOW "[*] Removing base .ko files..."
rm -f "${MODULES_DIR}"/*.ko

cecho YELLOW "[*] Copying built modules..."
find "${BUILD_MODULES_DIR}" -type f -name "*.ko" | while read -r ko; do
    cp -p "${ko}" "${MODULES_DIR}/"
done

NEW_KO_COUNT=$(find "${MODULES_DIR}" -name "*.ko" | wc -l)
cecho GREEN "[✓] Replaced with ${NEW_KO_COUNT} built modules"

# Rename wlan.ko → qca_cld3_wlan.ko (before strip/depmod)
if [ -f "${MODULES_DIR}/wlan.ko" ]; then
    mv "${MODULES_DIR}/wlan.ko" "${MODULES_DIR}/qca_cld3_wlan.ko"
    cecho GREEN "[✓] Renamed wlan.ko → qca_cld3_wlan.ko"
fi

# Run depmod
cecho YELLOW "[*] Running depmod..."

DEPMOD_STAGING="${RUN_DIR}/depmod_staging"
DEPMOD_VER=$(cat ${KDIR}/out/include/config/kernel.release)
DEPMOD_MOD_DIR="${DEPMOD_STAGING}/lib/modules/${DEPMOD_VER}"
mkdir -p "${DEPMOD_MOD_DIR}"

# Copy .ko into depmod staging
cp -p "${MODULES_DIR}"/*.ko "${DEPMOD_MOD_DIR}"/

# Create empty placeholder files to suppress warnings
touch "${DEPMOD_MOD_DIR}/modules.order"
touch "${DEPMOD_MOD_DIR}/modules.builtin"
touch "${DEPMOD_MOD_DIR}/modules.builtin.modinfo"

# Run depmod
depmod -a -b "${DEPMOD_STAGING}" "${DEPMOD_VER}"

# Copy generated depmod files back
for f in modules.alias modules.dep modules.softdep; do
    if [ -f "${DEPMOD_MOD_DIR}/${f}" ]; then
        cp -p "${DEPMOD_MOD_DIR}/${f}" "${MODULES_DIR}/"
    fi
done

cecho GREEN "[✓] depmod complete"

# Fix paths in modules.dep
cecho YELLOW "[*] Fixing module paths in modules.dep..."

# Remove path prefix in the form of 'lib/modules/<something>/'
sed -i 's|[^ :]*lib/modules/[^/]*/||g' "${MODULES_DIR}/modules.dep"
# Find '.ko' modules and root them to '/vendor_dlkm/lib/modules/'
sed -i 's|\([a-zA-Z0-9_.-]*\.ko\)|/vendor_dlkm/lib/modules/\1|g' "${MODULES_DIR}/modules.dep"

cecho GREEN "[✓] Paths fixed"

# modules.load — generated from present .ko files
cecho YELLOW "[*] Generating modules.load..."

# Generate modules.load
# Don't add modules that are in exclude set or blocklist
: > "${MODULES_DIR}/modules.load"
for ko in "${MODULES_DIR}"/*.ko; do
    mod_name=$(basename "${ko}" .ko)
    if [ -z "${EXCLUDE_SET[${mod_name}]+x}" ] && [ -z "${BLOCKLIST_SET[${mod_name}]+x}" ]; then
        echo "${mod_name}" >> "${MODULES_DIR}/modules.load"
    fi
done

LOAD_COUNT=$(wc -l < "${MODULES_DIR}/modules.load")
cecho GREEN "[✓] modules.load: ${LOAD_COUNT} entries (${#EXCLUDE_SET[@]} excluded, ${#BLOCKLIST_SET[@]} blocklisted)"

cecho GREEN "[✓] modules.blocklist: preserved from base"

# Build vendor_dlkm.img (EROFS)
OUT_IMG="${OUT_DIR}/vendor_dlkm.img"

cecho YELLOW "[*] Building EROFS vendor_dlkm image..."

FILE_CONTEXTS="${RUN_DIR}/file_contexts"
cat <<'EOF' >"${FILE_CONTEXTS}"
/ u:object_r:vendor_file:s0
/vendor_dlkm(/.*)? u:object_r:vendor_file:s0
/vendor_dlkm/etc(/.*)? u:object_r:vendor_configs_file:s0
EOF

mkfs.erofs \
    --mount-point=/vendor_dlkm \
    --all-root \
    --file-contexts="${FILE_CONTEXTS}" \
    -zlz4 \
    -b4096 \
    -T1230768000 \
    "${OUT_IMG}" \
    "${EXTRACT_DIR}"

# Check size against original partition
ORIG_SIZE=$(stat --format="%s" "${BASE_IMG}")
NEW_SIZE=$(stat --format="%s" "${OUT_IMG}")

if [ "${NEW_SIZE}" -le "${ORIG_SIZE}" ]; then
    cecho YELLOW "[*] Padding image to match partition size (${ORIG_SIZE} bytes)..."
    truncate -s "${ORIG_SIZE}" "${OUT_IMG}"
else
    cecho LIGHT_RED "[!] WARNING: New image (${NEW_SIZE}) > original partition (${ORIG_SIZE})!"
    cecho LIGHT_RED "    Image may not fit! Consider removing unused modules."
fi

IMG_SIZE=$(du -sh "${OUT_IMG}" | cut -f1)
cecho GREEN "[✓] Created ${OUT_IMG} (${IMG_SIZE})"

# Verify
cecho YELLOW "[*] Verifying image..."
fsck.erofs "${OUT_IMG}" 2>&1 && cecho GREEN "[✓] Image passed fsck" || cecho LIGHT_RED "[✗] Image failed fsck!"

# Copy vendor ramdisk modules
mkdir -p build/modules
cp ${MODULES_DIR}/msm_drm.ko build/modules/
cp ${MODULES_DIR}/apr_dlkm.ko build/modules/
cp ${MODULES_DIR}/q6_pdr_dlkm.ko build/modules/
cp ${MODULES_DIR}/q6_notifier_dlkm.ko build/modules/
cp ${MODULES_DIR}/adsp_loader_dlkm.ko build/modules/
cp ${MODULES_DIR}/snd_event_dlkm.ko build/modules/

# Summary
echo ""
cecho GREEN "[✓] Done!"
echo "    Work dir:    ${RUN_DIR}"
echo "    Out dir:     ${OUT_DIR}"
echo "    Modules:     ${NEW_KO_COUNT} .ko files"
echo "    Image:       ${OUT_IMG} (${IMG_SIZE})"
echo "    Extracted:   ${EXTRACT_DIR}"
echo "    Depmod:      ${DEPMOD_STAGING}"
echo "    Contexts:    ${FILE_CONTEXTS}"