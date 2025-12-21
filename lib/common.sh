#!/usr/bin/env bash
# common.sh - Shared functions for bootstrap system
# Logging, colors, OS detection, idempotency helpers

set -euo pipefail

# =============================================================================
# COLORS AND FORMATTING
# =============================================================================

# Only use colors if stdout is a terminal
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' BOLD='' DIM='' RESET=''
fi

# =============================================================================
# LOGGING
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

log_step() {
    echo -e "${PURPLE}[STEP]${RESET} ${BOLD}$*${RESET}"
}

log_skip() {
    echo -e "${DIM}[SKIP]${RESET} $*"
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${DIM}[DEBUG] $*${RESET}"
    fi
}

# Section header
section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}${BOLD}  $*${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# =============================================================================
# USER INTERACTION
# =============================================================================

# Prompt for yes/no (default no)
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -rp "$prompt" response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy] ]]
}

# Prompt for yes/no (default yes)
confirm_yes() {
    confirm "$1" "y"
}

# Select from options
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    echo -e "${BOLD}$prompt${RESET}"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    local choice
    while true; do
        read -rp "Choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice-1))]}"
            return 0
        fi
        echo "Invalid choice. Try again."
    done
}

# Multi-select from options (space-separated numbers)
multi_select() {
    local prompt="$1"
    shift
    local options=("$@")

    echo -e "${BOLD}$prompt${RESET}"
    echo -e "${DIM}(Enter space-separated numbers, or 'all' for everything, empty for none)${RESET}"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done

    local input
    read -rp "Choices: " input

    if [[ "$input" == "all" ]]; then
        printf '%s\n' "${options[@]}"
        return 0
    fi

    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#options[@]} )); then
            echo "${options[$((num-1))]}"
        fi
    done
}

# =============================================================================
# OS DETECTION
# =============================================================================

detect_os() {
    local os=""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|linuxmint|elementary)
                os="debian"
                ;;
            fedora|rhel|centos|rocky|alma)
                os="fedora"
                ;;
            opensuse*|suse|sles)
                os="opensuse"
                ;;
            arch|manjaro|endeavouros)
                os="arch"
                ;;
            *)
                os="linux"
                ;;
        esac
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        os="windows"
    else
        os="unknown"
    fi

    echo "$os"
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

detect_distro_version() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${VERSION_ID:-unknown}"
    else
        echo "unknown"
    fi
}

is_wsl() {
    [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version
}

is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Get architecture
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armhf"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# =============================================================================
# IDEMPOTENCY HELPERS
# =============================================================================

# Check if a command exists
cmd_exists() {
    command -v "$1" &>/dev/null
}

# Check if a file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if a directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Check if a symlink exists and points to expected target
symlink_correct() {
    local link="$1"
    local target="$2"
    [[ -L "$link" ]] && [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]
}

# Run command only if condition is false
run_if_missing() {
    local check_cmd="$1"
    shift
    if ! eval "$check_cmd"; then
        "$@"
    else
        log_skip "Already satisfied: $check_cmd"
    fi
}

# Ensure directory exists
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# =============================================================================
# VERSION COMPARISON
# =============================================================================

# Compare semantic versions: returns 0 if $1 >= $2
version_gte() {
    local v1="$1"
    local v2="$2"

    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"

    printf '%s\n%s\n' "$v2" "$v1" | sort -V -C
}

# Get version of a command (tries --version, -v, -V)
get_version() {
    local cmd="$1"
    local version=""

    if ! cmd_exists "$cmd"; then
        echo ""
        return 1
    fi

    # Try common version flags
    version=$("$cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1) ||
    version=$("$cmd" -v 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1) ||
    version=$("$cmd" -V 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1) ||
    version=""

    echo "$version"
}

# =============================================================================
# PATH MANAGEMENT
# =============================================================================

# Add to PATH if not already present
add_to_path() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

# =============================================================================
# NETWORK HELPERS
# =============================================================================

# Check if we can reach the internet
has_internet() {
    ping -c 1 -W 2 8.8.8.8 &>/dev/null || ping -c 1 -W 2 1.1.1.1 &>/dev/null
}

# Download file with progress
download() {
    local url="$1"
    local dest="$2"

    if cmd_exists curl; then
        curl -fsSL "$url" -o "$dest"
    elif cmd_exists wget; then
        wget -q "$url" -O "$dest"
    else
        log_error "Neither curl nor wget available"
        return 1
    fi
}

# =============================================================================
# SCRIPT CONTEXT
# =============================================================================

# Get the directory where the bootstrap scripts live
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -L "$source" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")/.." && pwd
}

# Export common variables
export BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-$(get_script_dir)}"
export CONFIGS_DIR="${BOOTSTRAP_DIR}/configs"
export MODULES_DIR="${BOOTSTRAP_DIR}/modules"
export LIB_DIR="${BOOTSTRAP_DIR}/lib"

# Detect OS once
export DETECTED_OS="${DETECTED_OS:-$(detect_os)}"
export DETECTED_DISTRO="${DETECTED_DISTRO:-$(detect_distro)}"
export DETECTED_ARCH="${DETECTED_ARCH:-$(detect_arch)}"
export IS_WSL="${IS_WSL:-$(is_wsl && echo 1 || echo 0)}"
