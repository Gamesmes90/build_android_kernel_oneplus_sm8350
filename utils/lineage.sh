#!/bin/bash
source utils/colors.sh

DEVICE="${1:-}"

URL=$(curl -s "https://download.lineageos.org/api/v1/${DEVICE}/nightly/1" \
  | jq -r '.response[0].url')
if [[ -z "$URL" || "$URL" == "null" ]]; then
  cecho RED "No download URL found for device '${DEVICE}'" >&2
  exit 1
fi

cecho YELLOW "Attempting to download Lineage OS for '${DEVICE}'..."

if ! wget -c "$URL"; then
  cecho RED "Download failed for URL: $URL" >&2
  exit 1
fi

cecho GREEN "Lineage OS for '${DEVICE}' downloaded successfully."