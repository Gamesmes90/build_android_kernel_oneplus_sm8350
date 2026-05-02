#!/usr/bin/env bash

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
REVERSE='\033[7m'

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

LIGHT_BLACK='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_MAGENTA='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
LIGHT_WHITE='\033[1;37m'

# Colored echo wrapper function
# Usage: echo COLOR "text"
# Example: echo RED "Error: Something went wrong"
# Example: echo GREEN "Success: Build complete"
cecho() {
    local color=$1
    shift
    command echo -e "${!color}$@${RESET}"
}

# Example usage:
# echo RED "Error: Something went wrong"
# echo GREEN "Success: Build complete"