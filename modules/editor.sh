#!/usr/bin/env bash
# editor.sh - Neovim installation and configuration

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Neovim config source: "github", "lazyvim", "astronvim", "nvchad", "local", "none"
#   github   = Clone from EDITOR_NVIM_REPO (your own config)
#   lazyvim  = LazyVim starter
#   astronvim = AstroNvim starter
#   nvchad   = NvChad starter
#   local    = Symlink from configs/nvim in this repo
#   none     = Don't install any config
EDITOR_NVIM_DISTRO="${EDITOR_NVIM_DISTRO:-github}"

# GitHub repo for custom config (used when EDITOR_NVIM_DISTRO=github)
# Format: "username/repo" - will use SSH: git@github.com:username/repo.git
EDITOR_NVIM_REPO="${EDITOR_NVIM_REPO:-}"

# Minimum Neovim version required for modern configs
NVIM_MIN_VERSION="${NVIM_MIN_VERSION:-0.10.0}"

# Always install latest Neovim (via AppImage on old distros)
EDITOR_INSTALL_LATEST="${EDITOR_INSTALL_LATEST:-true}"

# Clean nvim data directories on fresh install
EDITOR_CLEAN_DATA="${EDITOR_CLEAN_DATA:-true}"

# =============================================================================
# NEOVIM INSTALLATION
# =============================================================================

install_neovim() {
    section "Installing Neovim"

    local current_version=""
    local need_install=false

    if cmd_exists nvim; then
        current_version="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        log_info "Current Neovim version: $current_version"

        if ! version_gte "$current_version" "$NVIM_MIN_VERSION"; then
            log_warn "Neovim $current_version is too old (need >= $NVIM_MIN_VERSION)"
            need_install=true
        else
            log_success "Neovim $current_version meets requirements"
        fi
    else
        need_install=true
    fi

    if [[ "$need_install" == "true" ]]; then
        install_neovim_latest
    fi
}

install_neovim_latest() {
    log_info "Installing latest Neovim..."

    case "$DETECTED_OS" in
        macos)
            if [[ "$PKG_MANAGER" == "brew" ]]; then
                brew install neovim
            fi
            ;;
        debian)
            # Ubuntu's apt neovim is ancient - always use AppImage
            # Even 24.04 has 0.9.x which is behind latest
            install_neovim_appimage
            ;;
        fedora)
            # Fedora usually has recent neovim
            pkg_install neovim
            # Verify version, fall back to AppImage if too old
            local installed_version
            installed_version="$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")"
            if ! version_gte "$installed_version" "$NVIM_MIN_VERSION"; then
                log_warn "Package manager neovim too old, using AppImage"
                install_neovim_appimage
            fi
            ;;
        arch)
            pkg_install neovim
            ;;
        opensuse)
            pkg_install neovim
            ;;
        *)
            install_neovim_appimage
            ;;
    esac
}

install_neovim_appimage() {
    log_info "Installing Neovim via AppImage (latest stable)..."

    local install_dir="$HOME/.local/bin"
    local nvim_path="$install_dir/nvim"
    local extract_dir="$HOME/.local/lib/nvim"

    ensure_dir "$install_dir"

    # Check architecture and set appropriate AppImage filename
    local arch
    arch="$(uname -m)"
    local appimage_name

    case "$arch" in
        x86_64|amd64)
            appimage_name="nvim-linux-x86_64.appimage"
            ;;
        aarch64|arm64)
            appimage_name="nvim-linux-arm64.appimage"
            ;;
        *)
            log_warn "Unknown architecture: $arch, trying package manager..."
            pkg_install neovim
            return
            ;;
    esac

    # Remove old installation
    rm -rf "$extract_dir" 2>/dev/null || true
    rm -f "$nvim_path" 2>/dev/null || true

    local appimage_url="https://github.com/neovim/neovim/releases/latest/download/${appimage_name}"

    log_info "Downloading Neovim AppImage..."
    download "$appimage_url" "$nvim_path"
    chmod +x "$nvim_path"

    # Test if AppImage runs directly (needs FUSE)
    if "$nvim_path" --version &>/dev/null; then
        log_success "Neovim AppImage installed to $nvim_path"
    else
        # Extract AppImage (FUSE not available in WSL by default)
        log_info "Extracting AppImage (FUSE not available)..."
        ensure_dir "$extract_dir"
        cd "$extract_dir"
        "$nvim_path" --appimage-extract &>/dev/null || {
            log_error "Failed to extract AppImage"
            return 1
        }
        rm -f "$nvim_path"
        ln -sf "$extract_dir/squashfs-root/usr/bin/nvim" "$nvim_path"

        if "$nvim_path" --version &>/dev/null; then
            local version
            version="$("$nvim_path" --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
            log_success "Neovim $version installed (extracted AppImage)"
        else
            log_error "Failed to install Neovim"
            return 1
        fi
    fi
}

# =============================================================================
# NEOVIM CONFIG INSTALLATION
# =============================================================================

install_nvim_config_github() {
    local repo="$1"

    section "Installing Neovim Config from GitHub"

    if [[ -z "$repo" ]]; then
        log_error "No GitHub repo specified. Set EDITOR_NVIM_REPO='username/repo'"
        return 1
    fi

    local nvim_config="$HOME/.config/nvim"
    local repo_url="git@github.com:${repo}.git"

    # Check if already cloned from same repo
    if [[ -d "$nvim_config/.git" ]]; then
        local current_remote
        current_remote="$(git -C "$nvim_config" remote get-url origin 2>/dev/null || echo "")"
        if [[ "$current_remote" == *"$repo"* ]]; then
            log_info "Config already cloned from $repo, pulling latest..."
            git -C "$nvim_config" pull --rebase || log_warn "Pull failed, continuing with existing"
            return 0
        fi
    fi

    # Backup existing config
    if [[ -d "$nvim_config" ]] || [[ -L "$nvim_config" ]]; then
        log_info "Backing up existing Neovim config..."
        rm -rf "$nvim_config.backup" 2>/dev/null || true
        mv "$nvim_config" "$nvim_config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Clean data directories for fresh start
    if [[ "$EDITOR_CLEAN_DATA" == "true" ]]; then
        log_info "Cleaning Neovim data directories..."
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
        rm -rf "$HOME/.cache/nvim"
    fi

    log_info "Cloning $repo..."
    git clone "$repo_url" "$nvim_config"

    log_success "Neovim config installed from $repo"
    log_info "Run 'nvim' to complete setup (plugins will auto-install)"
}

install_lazyvim() {
    section "Installing LazyVim"

    local nvim_config="$HOME/.config/nvim"

    if [[ -d "$nvim_config" ]] && [[ -f "$nvim_config/lua/config/lazy.lua" ]]; then
        log_skip "LazyVim already installed"
        return 0
    fi

    # Backup existing config
    if [[ -d "$nvim_config" ]] || [[ -L "$nvim_config" ]]; then
        mv "$nvim_config" "$nvim_config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    if [[ "$EDITOR_CLEAN_DATA" == "true" ]]; then
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
        rm -rf "$HOME/.cache/nvim"
    fi

    log_info "Cloning LazyVim starter..."
    git clone https://github.com/LazyVim/starter "$nvim_config"
    rm -rf "$nvim_config/.git"

    log_success "LazyVim installed"
    log_info "Run 'nvim' to complete setup (plugins will auto-install)"
}

install_astronvim() {
    section "Installing AstroNvim"

    local nvim_config="$HOME/.config/nvim"

    if [[ -d "$nvim_config" ]] || [[ -L "$nvim_config" ]]; then
        mv "$nvim_config" "$nvim_config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    if [[ "$EDITOR_CLEAN_DATA" == "true" ]]; then
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
    fi

    git clone --depth 1 https://github.com/AstroNvim/template "$nvim_config"
    rm -rf "$nvim_config/.git"

    log_success "AstroNvim installed"
}

install_nvchad() {
    section "Installing NvChad"

    local nvim_config="$HOME/.config/nvim"

    if [[ -d "$nvim_config" ]] || [[ -L "$nvim_config" ]]; then
        mv "$nvim_config" "$nvim_config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    if [[ "$EDITOR_CLEAN_DATA" == "true" ]]; then
        rm -rf "$HOME/.local/share/nvim"
        rm -rf "$HOME/.local/state/nvim"
    fi

    git clone https://github.com/NvChad/starter "$nvim_config"
    rm -rf "$nvim_config/.git"

    log_success "NvChad installed"
}

link_local_nvim_config() {
    section "Linking Local Neovim Config"

    local config_dir="$BOOTSTRAP_DIR/configs/nvim"
    local nvim_config="$HOME/.config/nvim"

    if [[ ! -d "$config_dir" ]] || [[ -z "$(ls -A "$config_dir" 2>/dev/null)" ]]; then
        log_warn "No nvim config found at $config_dir"
        log_info "You can add your config there or use EDITOR_NVIM_DISTRO=github"
        return 0
    fi

    if [[ -d "$nvim_config" ]] && [[ ! -L "$nvim_config" ]]; then
        mv "$nvim_config" "$nvim_config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    safe_symlink "$config_dir" "$nvim_config"
    log_success "Local Neovim config linked"
}

# =============================================================================
# NEOVIM DEPENDENCIES
# =============================================================================

install_nvim_dependencies() {
    section "Installing Neovim Dependencies"

    # Required for many plugins
    pkg_install git
    pkg_install curl
    pkg_install unzip

    # For clipboard support (not needed in WSL - uses Windows clipboard)
    if is_linux && [[ "$IS_WSL" != "1" ]]; then
        pkg_install xclip
    fi

    # Build tools for some plugins (tree-sitter compilation, etc.)
    pkg_install make
    pkg_install gcc 2>/dev/null || pkg_install build-essential 2>/dev/null || true

    log_success "Neovim dependencies installed"
}

# =============================================================================
# FONTS
# =============================================================================

install_nerd_fonts() {
    section "Installing Nerd Fonts"

    local font_dir
    if is_macos; then
        font_dir="$HOME/Library/Fonts"
    else
        font_dir="$HOME/.local/share/fonts"
    fi

    ensure_dir "$font_dir"

    # Check if JetBrains Mono Nerd Font is installed
    if ls "$font_dir"/*JetBrains*Nerd* &>/dev/null 2>&1 || fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
        log_skip "JetBrains Mono Nerd Font already installed"
        return 0
    fi

    log_info "Installing JetBrains Mono Nerd Font..."

    local temp_dir
    temp_dir="$(mktemp -d)"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

    if download "$font_url" "$temp_dir/JetBrainsMono.zip"; then
        unzip -o "$temp_dir/JetBrainsMono.zip" -d "$font_dir" '*.ttf' 2>/dev/null || true
        rm -rf "$temp_dir"

        # Update font cache on Linux
        if is_linux && cmd_exists fc-cache; then
            fc-cache -fv "$font_dir" &>/dev/null
        fi

        log_success "JetBrains Mono Nerd Font installed"
    else
        log_warn "Failed to download Nerd Font"
        rm -rf "$temp_dir"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

install_editor() {
    install_neovim
    install_nvim_dependencies
    install_nerd_fonts

    case "$EDITOR_NVIM_DISTRO" in
        github)
            install_nvim_config_github "$EDITOR_NVIM_REPO"
            ;;
        lazyvim)
            install_lazyvim
            ;;
        astronvim)
            install_astronvim
            ;;
        nvchad)
            install_nvchad
            ;;
        local)
            link_local_nvim_config
            ;;
        none)
            log_info "Skipping Neovim config installation"
            ;;
        *)
            log_warn "Unknown distro: $EDITOR_NVIM_DISTRO"
            log_info "Valid options: github, lazyvim, astronvim, nvchad, local, none"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_editor
fi
