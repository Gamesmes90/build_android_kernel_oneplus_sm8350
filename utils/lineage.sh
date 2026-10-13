#!/bin/bash
source utils/colors.sh

DEVICE="${1:-}"

cecho YELLOW "Attempting to download Lineage OS for '${DEVICE}'..."

if ! curl -L -O "https://github.com/Gamesmes90/build_android_kernel_oneplus_sm8350/releases/download/a16/lineage-23.2-20261005-nightly-${DEVICE}-signed.zip"; then
  cecho RED "Download failed for URL: $URL" >&2
  exit 1
fi

cecho GREEN "Lineage OS for '${DEVICE}' downloaded successfully."