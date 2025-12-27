#!/usr/bin/env bash
# tools.sh - Modern CLI tools installation
# Replaces: cat->bat, ls->eza, cd->zoxide, etc.

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Core tools (always install)
TOOLS_CORE="${TOOLS_CORE:-true}"

# Enhanced tools (modern replacements)
TOOLS_ENHANCED="${TOOLS_ENHANCED:-true}"

# Development tools
TOOLS_DEV="${TOOLS_DEV:-true}"

# System monitoring tools
TOOLS_MONITORING="${TOOLS_MONITORING:-true}"

# =============================================================================
# CORE TOOLS
# =============================================================================

install_core_tools() {
    if [[ "$TOOLS_CORE" != "true" ]]; then
        log_skip "Core tools installation disabled"
        return 0
    fi

    section "Installing Core Tools"

    local core_packages=(
        git
        curl
        wget
        unzip
        jq
        tree
        make
    )

    for pkg in "${core_packages[@]}"; do
        pkg_install "$pkg"
    done

    log_success "Core tools installed"
}

# =============================================================================
# ENHANCED CLI TOOLS
# =============================================================================

install_enhanced_tools() {
    if [[ "$TOOLS_ENHANCED" != "true" ]]; then
        log_skip "Enhanced tools installation disabled"
        return 0
    fi

    section "Installing Enhanced CLI Tools"

    # bat - better cat with syntax highlighting
    install_bat

    # eza - modern ls replacement (successor to exa)
    install_eza

    # fzf - fuzzy finder
    install_fzf

    # zoxide - smarter cd
    install_zoxide

    # delta - better git diff
    install_delta

    # tldr - simplified man pages
    install_tldr

    log_success "Enhanced CLI tools installed"
}

install_bat() {
    if cmd_exists bat || cmd_exists batcat; then
        log_skip "bat already installed"
        return 0
    fi

    pkg_install bat

    # On Debian/Ubuntu, bat is installed as batcat
    if cmd_exists batcat && ! cmd_exists bat; then
        ensure_dir "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        log_info "Created bat symlink for batcat"
    fi
}

install_eza() {
    if cmd_exists eza; then
        log_skip "eza already installed"
        return 0
    fi

    # eza might need external repo on older systems
    add_external_repo eza
    pkg_update 2>/dev/null || true
    pkg_install eza

    # Fallback to cargo if package not available
    if ! cmd_exists eza && cmd_exists cargo; then
        log_info "Installing eza via cargo..."
        cargo install eza
    fi
}

install_fzf() {
    if cmd_exists fzf; then
        log_skip "fzf already installed"
        return 0
    fi

    pkg_install fzf

    # Install fzf shell integration
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        log_info "fzf shell integration available at /usr/share/doc/fzf/examples/"
    fi
}

install_zoxide() {
    if cmd_exists zoxide; then
        log_skip "zoxide already installed"
        return 0
    fi

    pkg_install zoxide

    # Fallback to cargo
    if ! cmd_exists zoxide && cmd_exists cargo; then
        cargo install zoxide
    fi

    log_info "Add 'eval \"\$(zoxide init zsh)\"' to .zshrc for zoxide integration"
}

install_delta() {
    if cmd_exists delta; then
        log_skip "delta already installed"
        return 0
    fi

    pkg_install delta

    # Fallback to cargo
    if ! cmd_exists delta && cmd_exists cargo; then
        cargo install git-delta
    fi
}

install_tldr() {
    if cmd_exists tldr; then
        log_skip "tldr already installed"
        return 0
    fi

    pkg_install tldr

    # Update tldr cache
    if cmd_exists tldr; then
        tldr --update 2>/dev/null || true
    fi
}

# =============================================================================
# DEVELOPMENT TOOLS
# =============================================================================

install_dev_tools() {
    if [[ "$TOOLS_DEV" != "true" ]]; then
        log_skip "Development tools installation disabled"
        return 0
    fi

    section "Installing Development Tools"

    # lazygit - terminal git UI
    install_lazygit

    # gh - GitHub CLI
    install_gh_cli

    # direnv - directory-based environment variables
    install_direnv

    log_success "Development tools installed"
}

install_lazygit() {
    if cmd_exists lazygit; then
        log_skip "lazygit already installed"
        return 0
    fi

    case "$PKG_MANAGER" in
        brew)
            brew install lazygit
            ;;
        dnf)
            sudo dnf install -y lazygit 2>/dev/null || install_lazygit_from_github
            ;;
        pacman)
            sudo pacman -S --noconfirm lazygit
            ;;
        zypper)
            sudo zypper install -y lazygit 2>/dev/null || install_lazygit_from_github
            ;;
        apt)
            # PPA doesn't support Ubuntu 24.04+, use GitHub releases
            install_lazygit_from_github
            ;;
        *)
            install_lazygit_from_github
            ;;
    esac
}

install_lazygit_from_github() {
    log_info "Installing lazygit from GitHub releases..."

    local install_dir="$HOME/.local/bin"
    ensure_dir "$install_dir"

    # Detect architecture
    local arch
    arch="$(uname -m)"
    local lazygit_arch
    case "$arch" in
        x86_64|amd64) lazygit_arch="x86_64" ;;
        aarch64|arm64) lazygit_arch="arm64" ;;
        *)
            log_warn "Unknown architecture: $arch, trying go install..."
            if cmd_exists go; then
                go install github.com/jesseduffield/lazygit@latest
            fi
            return
            ;;
    esac

    # Get latest version
    local latest_version
    latest_version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if [[ -z "$latest_version" ]]; then
        log_warn "Could not determine latest lazygit version, trying go install..."
        if cmd_exists go; then
            go install github.com/jesseduffield/lazygit@latest
        fi
        return
    fi

    local tarball="lazygit_${latest_version}_Linux_${lazygit_arch}.tar.gz"
    local url="https://github.com/jesseduffield/lazygit/releases/latest/download/${tarball}"

    local tmp_dir
    tmp_dir="$(mktemp -d)"

    if download "$url" "$tmp_dir/$tarball"; then
        tar -xzf "$tmp_dir/$tarball" -C "$tmp_dir"
        mv "$tmp_dir/lazygit" "$install_dir/lazygit"
        chmod +x "$install_dir/lazygit"
        rm -rf "$tmp_dir"
        log_success "lazygit $latest_version installed to $install_dir"
    else
        rm -rf "$tmp_dir"
        log_warn "Failed to download lazygit, trying go install..."
        if cmd_exists go; then
            go install github.com/jesseduffield/lazygit@latest
        fi
    fi
}

install_gh_cli() {
    if cmd_exists gh; then
        log_skip "GitHub CLI already installed"
        return 0
    fi

    case "$PKG_MANAGER" in
        apt)
            # GitHub CLI official repo
            if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                pkg_update
            fi
            sudo apt-get install -y gh
            ;;
        brew)
            brew install gh
            ;;
        dnf)
            sudo dnf install -y gh
            ;;
        *)
            log_warn "gh CLI installation not configured for $PKG_MANAGER"
            ;;
    esac
}

install_direnv() {
    if cmd_exists direnv; then
        log_skip "direnv already installed"
        return 0
    fi

    pkg_install direnv 2>/dev/null || {
        # Install from binary
        log_info "Installing direnv from binary..."
        curl -sfL https://direnv.net/install.sh | bash
    }
}

# =============================================================================
# MONITORING TOOLS
# =============================================================================

install_monitoring_tools() {
    if [[ "$TOOLS_MONITORING" != "true" ]]; then
        log_skip "Monitoring tools installation disabled"
        return 0
    fi

    section "Installing Monitoring Tools"

    # htop - interactive process viewer
    pkg_install htop

    # btop - even better top (if available)
    pkg_install btop 2>/dev/null || log_info "btop not available in repos"

    # ncdu - disk usage analyzer
    pkg_install ncdu

    log_success "Monitoring tools installed"
}

# =============================================================================
# ADDITIONAL USEFUL TOOLS
# =============================================================================

install_additional_tools() {
    section "Installing Additional Tools"

    # httpie - better curl for APIs (optional)
    if confirm "Install httpie (better curl for APIs)?"; then
        pkg_install httpie 2>/dev/null || pip install httpie 2>/dev/null || true
    fi

    # ranger - terminal file manager (optional)
    if confirm "Install ranger (terminal file manager)?"; then
        pkg_install ranger 2>/dev/null || pip install ranger-fm 2>/dev/null || true
    fi
}

# =============================================================================
# SHELL CONFIGURATION FOR TOOLS
# =============================================================================

configure_tool_aliases() {
    log_info "Tool aliases are configured in shell configs"
    log_info "See configs/shell/aliases.zsh for alias definitions"
}

# =============================================================================
# MAIN
# =============================================================================

install_tools() {
    install_core_tools
    install_enhanced_tools
    install_dev_tools
    install_monitoring_tools
    configure_tool_aliases

    log_success "All tools installed"
    log_info "Restart your shell or run 'source ~/.zshrc' to use new tools"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_tools
fi
