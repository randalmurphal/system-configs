#!/usr/bin/env bash
# packages.sh - Package manager abstraction layer
# Supports: apt, brew, dnf, zypper, pacman

# Source common if not already loaded
if [[ -z "${BOOTSTRAP_DIR:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# =============================================================================
# PACKAGE MANAGER DETECTION
# =============================================================================

detect_package_manager() {
    if is_macos && cmd_exists brew; then
        echo "brew"
    elif cmd_exists apt-get; then
        echo "apt"
    elif cmd_exists dnf; then
        echo "dnf"
    elif cmd_exists zypper; then
        echo "zypper"
    elif cmd_exists pacman; then
        echo "pacman"
    elif is_macos; then
        echo "brew-missing"
    else
        echo "unknown"
    fi
}

export PKG_MANAGER="${PKG_MANAGER:-$(detect_package_manager)}"

# =============================================================================
# PACKAGE NAME MAPPING
# =============================================================================

# Map generic package names to distro-specific names
# Format: generic_name -> apt:name,brew:name,dnf:name,zypper:name,pacman:name
declare -A PACKAGE_MAP=(
    # Core tools
    ["git"]="apt:git,brew:git,dnf:git,zypper:git,pacman:git"
    ["curl"]="apt:curl,brew:curl,dnf:curl,zypper:curl,pacman:curl"
    ["wget"]="apt:wget,brew:wget,dnf:wget,zypper:wget,pacman:wget"
    ["unzip"]="apt:unzip,brew:unzip,dnf:unzip,zypper:unzip,pacman:unzip"
    ["jq"]="apt:jq,brew:jq,dnf:jq,zypper:jq,pacman:jq"

    # Shell
    ["zsh"]="apt:zsh,brew:zsh,dnf:zsh,zypper:zsh,pacman:zsh"
    ["bash"]="apt:bash,brew:bash,dnf:bash,zypper:bash,pacman:bash"

    # Terminal multiplexer
    ["tmux"]="apt:tmux,brew:tmux,dnf:tmux,zypper:tmux,pacman:tmux"

    # Editors
    ["neovim"]="apt:neovim,brew:neovim,dnf:neovim,zypper:neovim,pacman:neovim"
    ["vim"]="apt:vim,brew:vim,dnf:vim,zypper:vim,pacman:vim"

    # Modern CLI tools
    ["bat"]="apt:bat,brew:bat,dnf:bat,zypper:bat,pacman:bat"
    ["ripgrep"]="apt:ripgrep,brew:ripgrep,dnf:ripgrep,zypper:ripgrep,pacman:ripgrep"
    ["fd"]="apt:fd-find,brew:fd,dnf:fd-find,zypper:fd,pacman:fd"
    ["eza"]="apt:eza,brew:eza,dnf:eza,zypper:eza,pacman:eza"
    ["fzf"]="apt:fzf,brew:fzf,dnf:fzf,zypper:fzf,pacman:fzf"
    ["zoxide"]="apt:zoxide,brew:zoxide,dnf:zoxide,zypper:zoxide,pacman:zoxide"
    ["htop"]="apt:htop,brew:htop,dnf:htop,zypper:htop,pacman:htop"
    ["btop"]="apt:btop,brew:btop,dnf:btop,zypper:btop,pacman:btop"
    ["ncdu"]="apt:ncdu,brew:ncdu,dnf:ncdu,zypper:ncdu,pacman:ncdu"
    ["tree"]="apt:tree,brew:tree,dnf:tree,zypper:tree,pacman:tree"
    ["tldr"]="apt:tldr,brew:tldr,dnf:tldr,zypper:tealdeer,pacman:tldr"
    ["delta"]="apt:git-delta,brew:git-delta,dnf:git-delta,zypper:git-delta,pacman:git-delta"
    ["lazygit"]="apt:lazygit,brew:lazygit,dnf:lazygit,zypper:lazygit,pacman:lazygit"

    # Build tools
    ["build-essential"]="apt:build-essential,brew:,dnf:@development-tools,zypper:-t pattern devel_basis,pacman:base-devel"
    ["cmake"]="apt:cmake,brew:cmake,dnf:cmake,zypper:cmake,pacman:cmake"
    ["make"]="apt:make,brew:make,dnf:make,zypper:make,pacman:make"

    # Libraries (for building Python, etc.)
    ["libssl"]="apt:libssl-dev,brew:openssl,dnf:openssl-devel,zypper:libopenssl-devel,pacman:openssl"
    ["libffi"]="apt:libffi-dev,brew:libffi,dnf:libffi-devel,zypper:libffi-devel,pacman:libffi"
    ["libreadline"]="apt:libreadline-dev,brew:readline,dnf:readline-devel,zypper:readline-devel,pacman:readline"
    ["libbz2"]="apt:libbz2-dev,brew:bzip2,dnf:bzip2-devel,zypper:libbz2-devel,pacman:bzip2"
    ["libsqlite3"]="apt:libsqlite3-dev,brew:sqlite,dnf:sqlite-devel,zypper:sqlite3-devel,pacman:sqlite"
    ["zlib"]="apt:zlib1g-dev,brew:zlib,dnf:zlib-devel,zypper:zlib-devel,pacman:zlib"
    ["liblzma"]="apt:liblzma-dev,brew:xz,dnf:xz-devel,zypper:xz-devel,pacman:xz"

    # Clipboard
    ["xclip"]="apt:xclip,brew:,dnf:xclip,zypper:xclip,pacman:xclip"
    ["xsel"]="apt:xsel,brew:,dnf:xsel,zypper:xsel,pacman:xsel"
    ["wl-clipboard"]="apt:wl-clipboard,brew:,dnf:wl-clipboard,zypper:wl-clipboard,pacman:wl-clipboard"

    # Fonts
    ["fontconfig"]="apt:fontconfig,brew:fontconfig,dnf:fontconfig,zypper:fontconfig,pacman:fontconfig"

    # Python (system)
    ["python3"]="apt:python3,brew:python@3.12,dnf:python3,zypper:python3,pacman:python"
    ["python3-pip"]="apt:python3-pip,brew:,dnf:python3-pip,zypper:python3-pip,pacman:python-pip"
    ["python3-venv"]="apt:python3-venv,brew:,dnf:python3-devel,zypper:python3-devel,pacman:"

    # Node (system fallback)
    ["nodejs"]="apt:nodejs,brew:node,dnf:nodejs,zypper:nodejs,pacman:nodejs"
    ["npm"]="apt:npm,brew:,dnf:npm,zypper:npm,pacman:npm"
)

# Get package name for current package manager
get_package_name() {
    local generic_name="$1"
    local mapping="${PACKAGE_MAP[$generic_name]:-}"

    if [[ -z "$mapping" ]]; then
        # No mapping, use generic name
        echo "$generic_name"
        return
    fi

    # Parse mapping for current package manager
    local pkg_name=""
    IFS=',' read -ra entries <<< "$mapping"
    for entry in "${entries[@]}"; do
        local mgr="${entry%%:*}"
        local name="${entry#*:}"
        if [[ "$mgr" == "$PKG_MANAGER" ]]; then
            pkg_name="$name"
            break
        fi
    done

    # If not found in mapping, use generic name
    echo "${pkg_name:-$generic_name}"
}

# =============================================================================
# PACKAGE OPERATIONS
# =============================================================================

# Update package lists
pkg_update() {
    log_step "Updating package lists..."
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update -qq
            ;;
        brew)
            brew update
            ;;
        dnf)
            sudo dnf check-update || true  # Returns 100 if updates available
            ;;
        zypper)
            sudo zypper refresh
            ;;
        pacman)
            sudo pacman -Sy
            ;;
        *)
            log_warn "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Install a single package
pkg_install() {
    local generic_name="$1"
    local pkg_name
    pkg_name="$(get_package_name "$generic_name")"

    # Empty package name means not available on this platform
    if [[ -z "$pkg_name" ]]; then
        log_skip "Package '$generic_name' not available on $PKG_MANAGER"
        return 0
    fi

    # Check if already installed
    if pkg_is_installed "$generic_name"; then
        log_skip "Package '$pkg_name' already installed"
        return 0
    fi

    log_info "Installing $pkg_name..."
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get install -y -qq "$pkg_name"
            ;;
        brew)
            brew install "$pkg_name"
            ;;
        dnf)
            # Handle group installs (start with @)
            if [[ "$pkg_name" == @* ]]; then
                sudo dnf group install -y "$pkg_name"
            else
                sudo dnf install -y "$pkg_name"
            fi
            ;;
        zypper)
            # Handle pattern installs (start with -t pattern)
            if [[ "$pkg_name" == "-t pattern"* ]]; then
                # shellcheck disable=SC2086
                sudo zypper install -y $pkg_name
            else
                sudo zypper install -y "$pkg_name"
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg_name"
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Install multiple packages
pkg_install_many() {
    for pkg in "$@"; do
        pkg_install "$pkg" || log_warn "Failed to install: $pkg"
    done
}

# Check if package is installed
pkg_is_installed() {
    local generic_name="$1"
    local pkg_name
    pkg_name="$(get_package_name "$generic_name")"

    [[ -z "$pkg_name" ]] && return 1

    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$pkg_name" 2>/dev/null | grep -q "^ii"
            ;;
        brew)
            brew list "$pkg_name" &>/dev/null
            ;;
        dnf)
            rpm -q "$pkg_name" &>/dev/null
            ;;
        zypper)
            rpm -q "$pkg_name" &>/dev/null
            ;;
        pacman)
            pacman -Q "$pkg_name" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Remove a package
pkg_remove() {
    local generic_name="$1"
    local pkg_name
    pkg_name="$(get_package_name "$generic_name")"

    [[ -z "$pkg_name" ]] && return 0

    case "$PKG_MANAGER" in
        apt)
            sudo apt-get remove -y "$pkg_name"
            ;;
        brew)
            brew uninstall "$pkg_name"
            ;;
        dnf)
            sudo dnf remove -y "$pkg_name"
            ;;
        zypper)
            sudo zypper remove -y "$pkg_name"
            ;;
        pacman)
            sudo pacman -R --noconfirm "$pkg_name"
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# =============================================================================
# HOMEBREW INSTALLATION (macOS)
# =============================================================================

install_homebrew() {
    if cmd_exists brew; then
        log_skip "Homebrew already installed"
        return 0
    fi

    if ! is_macos; then
        log_error "Homebrew installation only supported on macOS"
        return 1
    fi

    log_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    export PKG_MANAGER="brew"
}

# =============================================================================
# EXTERNAL PACKAGE SOURCES
# =============================================================================

# Add external repository (for packages not in default repos)
add_external_repo() {
    local repo_name="$1"

    case "$repo_name" in
        lazygit)
            case "$PKG_MANAGER" in
                apt)
                    # lazygit PPA
                    if [[ ! -f /etc/apt/sources.list.d/lazygit.list ]]; then
                        log_info "Adding lazygit repository..."
                        sudo add-apt-repository -y ppa:lazygit-team/release
                    fi
                    ;;
            esac
            ;;
        eza)
            case "$PKG_MANAGER" in
                apt)
                    # eza is in Ubuntu 24.04+ repos, but for older versions:
                    if ! pkg_is_installed eza && [[ "$(detect_distro_version)" < "24.04" ]]; then
                        log_info "Adding eza repository..."
                        sudo mkdir -p /etc/apt/keyrings
                        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                    fi
                    ;;
            esac
            ;;
    esac
}

# =============================================================================
# CARGO/BINARY FALLBACKS
# =============================================================================

# Install via cargo if package manager doesn't have it
cargo_install() {
    local crate="$1"
    local binary="${2:-$crate}"

    if cmd_exists "$binary"; then
        log_skip "$binary already installed"
        return 0
    fi

    if ! cmd_exists cargo; then
        log_warn "Cargo not available, cannot install $crate"
        return 1
    fi

    log_info "Installing $crate via cargo..."
    cargo install "$crate"
}

# Install from GitHub releases
github_release_install() {
    local repo="$1"      # e.g., "sharkdp/bat"
    local binary="$2"    # e.g., "bat"
    local version="${3:-latest}"

    if cmd_exists "$binary"; then
        log_skip "$binary already installed"
        return 0
    fi

    log_info "Installing $binary from GitHub releases..."

    local arch
    arch="$(detect_arch)"
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"

    # Determine download URL pattern
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    if [[ "$version" != "latest" ]]; then
        api_url="https://api.github.com/repos/$repo/releases/tags/$version"
    fi

    # This is a simplified version - real implementation would need to handle
    # different archive formats and binary locations
    log_warn "GitHub release installation not fully implemented for $binary"
    return 1
}
