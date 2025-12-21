#!/usr/bin/env bash
# shell.sh - ZSH installation and configuration module
# Supports: oh-my-zsh (default), zinit (optional)

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Plugin manager: "oh-my-zsh" or "zinit"
SHELL_PLUGIN_MANAGER="${SHELL_PLUGIN_MANAGER:-oh-my-zsh}"

# Plugins to install (space-separated)
SHELL_PLUGINS="${SHELL_PLUGINS:-zsh-autosuggestions zsh-syntax-highlighting}"

# Change default shell to zsh
SHELL_SET_DEFAULT="${SHELL_SET_DEFAULT:-true}"

# =============================================================================
# ZSH INSTALLATION
# =============================================================================

install_zsh() {
    section "Installing ZSH"

    if cmd_exists zsh; then
        local version
        version="$(zsh --version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
        log_success "ZSH already installed (version $version)"
    else
        pkg_install zsh
        log_success "ZSH installed"
    fi

    # Set as default shell
    if [[ "$SHELL_SET_DEFAULT" == "true" ]]; then
        set_default_shell
    fi
}

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ "$SHELL" == "$zsh_path" ]]; then
        log_skip "ZSH already default shell"
        return 0
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        log_info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    log_info "Setting ZSH as default shell..."
    chsh -s "$zsh_path"
    log_success "Default shell changed to ZSH (takes effect on next login)"
}

# =============================================================================
# OH-MY-ZSH
# =============================================================================

install_oh_my_zsh() {
    section "Installing Oh-My-ZSH"

    local omz_dir="$HOME/.oh-my-zsh"

    if [[ -d "$omz_dir" ]]; then
        log_skip "Oh-My-ZSH already installed"
    else
        log_info "Installing Oh-My-ZSH..."
        # Install without changing shell (we handle that separately)
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_success "Oh-My-ZSH installed"
    fi

    # Install plugins
    install_omz_plugins
}

install_omz_plugins() {
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    for plugin in $SHELL_PLUGINS; do
        local plugin_dir="$custom_dir/plugins/$plugin"

        if [[ -d "$plugin_dir" ]]; then
            log_skip "Plugin already installed: $plugin"
            continue
        fi

        log_info "Installing plugin: $plugin..."
        case "$plugin" in
            zsh-autosuggestions)
                git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
                ;;
            zsh-syntax-highlighting)
                git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir"
                ;;
            zsh-completions)
                git clone --depth=1 https://github.com/zsh-users/zsh-completions "$plugin_dir"
                ;;
            zsh-history-substring-search)
                git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search "$plugin_dir"
                ;;
            fast-syntax-highlighting)
                git clone --depth=1 https://github.com/zdharma-continuum/fast-syntax-highlighting "$plugin_dir"
                ;;
            fzf-tab)
                git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$plugin_dir"
                ;;
            *)
                log_warn "Unknown plugin: $plugin"
                continue
                ;;
        esac
        log_success "Installed plugin: $plugin"
    done
}

# =============================================================================
# ZINIT (Alternative to oh-my-zsh)
# =============================================================================

install_zinit() {
    section "Installing Zinit"

    local zinit_home="$HOME/.local/share/zinit/zinit.git"

    if [[ -d "$zinit_home" ]]; then
        log_skip "Zinit already installed"
    else
        log_info "Installing Zinit..."
        mkdir -p "$(dirname "$zinit_home")"
        git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
        log_success "Zinit installed"
    fi
}

# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

copy_zsh_config() {
    section "Copying ZSH Configuration"

    local source_dir="$BOOTSTRAP_DIR/configs/shell"
    local target_dir="$HOME/.config/zsh"

    # Check if configs exist
    if [[ ! -d "$source_dir" ]]; then
        log_error "Shell configs not found at $source_dir"
        return 1
    fi

    # Create target directory
    ensure_dir "$target_dir"

    # Copy modular config files (won't overwrite existing)
    safe_copy "$source_dir/core.zsh" "$target_dir/core.zsh"
    safe_copy "$source_dir/aliases.zsh" "$target_dir/aliases.zsh"
    safe_copy "$source_dir/functions.zsh" "$target_dir/functions.zsh"
    safe_copy "$source_dir/path.zsh" "$target_dir/path.zsh"
    safe_copy "$source_dir/toolchains.zsh" "$target_dir/toolchains.zsh"

    # Create ~/.zshrc if it doesn't exist
    if [[ ! -e "$HOME/.zshrc" ]] || [[ -L "$HOME/.zshrc" ]]; then
        # Remove symlink if present
        [[ -L "$HOME/.zshrc" ]] && rm "$HOME/.zshrc"

        cat > "$HOME/.zshrc" << 'ZSHRCEOF'
# ZSH Configuration - Sources modular configs from ~/.config/zsh/
# Feel free to customize this file and add your own settings below

ZSHRC_DIR="$HOME/.config/zsh"

# Source modular configs
[[ -f "$ZSHRC_DIR/core.zsh" ]] && source "$ZSHRC_DIR/core.zsh"
[[ -f "$ZSHRC_DIR/aliases.zsh" ]] && source "$ZSHRC_DIR/aliases.zsh"
[[ -f "$ZSHRC_DIR/functions.zsh" ]] && source "$ZSHRC_DIR/functions.zsh"
[[ -f "$ZSHRC_DIR/path.zsh" ]] && source "$ZSHRC_DIR/path.zsh"
[[ -f "$ZSHRC_DIR/toolchains.zsh" ]] && source "$ZSHRC_DIR/toolchains.zsh"

# =============================================================================
# YOUR CUSTOM SETTINGS BELOW
# =============================================================================

ZSHRCEOF
        log_success "Created ~/.zshrc"
    else
        log_skip "~/.zshrc already exists (not overwriting)"
    fi

    log_success "ZSH configuration copied to $target_dir"
}

# Alias for backwards compatibility
link_zsh_config() {
    copy_zsh_config
}

# =============================================================================
# MAIN
# =============================================================================

install_shell() {
    install_zsh

    case "$SHELL_PLUGIN_MANAGER" in
        oh-my-zsh|omz)
            install_oh_my_zsh
            ;;
        zinit)
            install_zinit
            ;;
        none)
            log_info "Skipping plugin manager installation"
            ;;
        *)
            log_warn "Unknown plugin manager: $SHELL_PLUGIN_MANAGER, using oh-my-zsh"
            install_oh_my_zsh
            ;;
    esac

    link_zsh_config
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_shell
fi
