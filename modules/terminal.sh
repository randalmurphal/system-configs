#!/usr/bin/env bash
# terminal.sh - Terminal multiplexer and emulator configuration
# Installs: tmux, TPM (Tmux Plugin Manager)
# Configures: WezTerm (if available on Windows host)

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Install tmux plugins automatically
TERMINAL_INSTALL_TPM="${TERMINAL_INSTALL_TPM:-true}"

# Install tmux plugins on first run
TERMINAL_INSTALL_PLUGINS="${TERMINAL_INSTALL_PLUGINS:-true}"

# Install sysinfo-daemon for WezTerm status bar (requires Rust/cargo)
TERMINAL_SYSINFO_DAEMON="${TERMINAL_SYSINFO_DAEMON:-false}"

# =============================================================================
# TMUX INSTALLATION
# =============================================================================

install_tmux() {
    section "Installing Tmux"

    if cmd_exists tmux; then
        local version
        version="$(tmux -V | grep -oE '[0-9]+\.[0-9]+[a-z]?')"
        log_success "Tmux already installed (version $version)"
    else
        pkg_install tmux
        log_success "Tmux installed"
    fi
}

# =============================================================================
# TPM (TMUX PLUGIN MANAGER)
# =============================================================================

install_tpm() {
    if [[ "$TERMINAL_INSTALL_TPM" != "true" ]]; then
        log_skip "TPM installation disabled"
        return 0
    fi

    section "Installing TPM (Tmux Plugin Manager)"

    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        log_skip "TPM already installed"
    else
        log_info "Installing TPM..."
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm_dir"
        log_success "TPM installed"
    fi
}

install_tmux_plugins() {
    if [[ "$TERMINAL_INSTALL_PLUGINS" != "true" ]]; then
        log_skip "Tmux plugin installation disabled"
        return 0
    fi

    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ ! -d "$tpm_dir" ]]; then
        log_warn "TPM not installed, skipping plugin installation"
        return 0
    fi

    log_info "Installing tmux plugins..."

    # Source tmux config to get plugin list, then install
    if [[ -f "$HOME/.tmux.conf" ]]; then
        # Run TPM install script
        "$tpm_dir/scripts/install_plugins.sh" || true
        log_success "Tmux plugins installed"
    else
        log_warn "No .tmux.conf found, skipping plugin installation"
    fi
}

# =============================================================================
# TMUX CONFIGURATION
# =============================================================================

link_tmux_config() {
    section "Linking Tmux Configuration"

    local config_dir="$BOOTSTRAP_DIR/configs/tmux"

    if [[ ! -d "$config_dir" ]]; then
        log_error "Tmux configs not found at $config_dir"
        return 1
    fi

    safe_symlink "$config_dir/.tmux.conf" "$HOME/.tmux.conf"
    log_success "Tmux configuration linked"
}

# =============================================================================
# WEZTERM CONFIGURATION
# =============================================================================

link_wezterm_config() {
    section "Linking WezTerm Configuration"

    local config_dir="$BOOTSTRAP_DIR/configs/wezterm"

    if [[ ! -d "$config_dir" ]]; then
        log_warn "WezTerm configs not found at $config_dir"
        return 0
    fi

    # WezTerm config location depends on OS
    if is_macos; then
        safe_symlink "$config_dir/.wezterm.lua" "$HOME/.wezterm.lua"
    elif [[ "$IS_WSL" == "1" ]]; then
        # For WSL, symlink to WSL home for local access
        safe_symlink "$config_dir/.wezterm.lua" "$HOME/.wezterm.lua"

        # Copy config directly to Windows (WezTerm runs on Windows, not WSL)
        local win_home
        win_home="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"
        if [[ -n "$win_home" && -d "$win_home" ]]; then
            log_info "Windows home detected: $win_home"
            cp "$config_dir/.wezterm.lua" "$win_home/.wezterm.lua"
            log_success "Copied WezTerm config to $win_home/.wezterm.lua"
        else
            log_warn "Could not detect Windows home directory"
        fi
    else
        safe_symlink "$config_dir/.wezterm.lua" "$HOME/.wezterm.lua"
    fi

    log_success "WezTerm configuration linked"
}

install_sysinfo_daemon() {
    if [[ "$TERMINAL_SYSINFO_DAEMON" != "true" ]]; then
        log_skip "Sysinfo daemon disabled (set TERMINAL_SYSINFO_DAEMON=true to enable)"
        return 0
    fi

    section "Installing Sysinfo Daemon"

    local daemon_dir="$BOOTSTRAP_DIR/configs/wezterm/sysinfo-daemon"

    if [[ ! -d "$daemon_dir" ]]; then
        log_error "Sysinfo daemon source not found at $daemon_dir"
        return 1
    fi

    # Check if already installed and running
    if [[ -f "$HOME/.local/bin/sysinfo-daemon" ]] && systemctl --user is-active sysinfo.service &>/dev/null; then
        log_skip "Sysinfo daemon already installed and running"
        return 0
    fi

    # Check for cargo (Rust toolchain)
    if ! cmd_exists cargo; then
        log_warn "Cargo not found - sysinfo-daemon requires Rust toolchain"
        log_info "Install Rust first: ./bootstrap.sh -m languages"
        return 0
    fi

    # Build the daemon
    log_info "Building sysinfo-daemon (Rust)..."
    (
        cd "$daemon_dir"
        cargo build --release 2>&1 | tail -5
    ) || {
        log_error "Failed to build sysinfo-daemon"
        return 1
    }

    # Install binary
    ensure_dir "$HOME/.local/bin"
    cp "$daemon_dir/target/release/sysinfo-daemon" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/sysinfo-daemon"
    log_success "Installed sysinfo-daemon binary"

    # Install systemd user service
    if [[ -f "$daemon_dir/sysinfo.service" ]]; then
        ensure_dir "$HOME/.config/systemd/user"
        cp "$daemon_dir/sysinfo.service" "$HOME/.config/systemd/user/"

        # Enable and start the service
        if cmd_exists systemctl; then
            systemctl --user daemon-reload
            systemctl --user enable sysinfo.service 2>/dev/null || true
            systemctl --user start sysinfo.service 2>/dev/null || true
            log_success "Sysinfo daemon service enabled and started"

            # Verify it's working
            sleep 0.3
            if [[ -f /tmp/sysinfo ]]; then
                log_info "Output: $(cat /tmp/sysinfo)"
            fi
        fi
    else
        log_warn "Systemd service file not found - daemon installed but not auto-started"
        log_info "Run manually: ~/.local/bin/sysinfo-daemon &"
    fi
}

# =============================================================================
# ADDITIONAL TERMINAL TOOLS
# =============================================================================

install_terminal_tools() {
    section "Installing Terminal Tools"

    # xclip for clipboard support in tmux
    if is_linux && [[ "$IS_WSL" != "1" ]]; then
        pkg_install xclip
    fi

    # Install dependencies for tmux plugins
    pkg_install bash  # Ensure bash is available for scripts
}

# =============================================================================
# MAIN
# =============================================================================

install_terminal() {
    install_tmux
    install_tpm
    link_tmux_config
    install_tmux_plugins
    link_wezterm_config
    install_terminal_tools

    # Optional: sysinfo-daemon for WezTerm status bar (Linux/WSL only)
    if is_linux || [[ "${IS_WSL:-0}" == "1" ]]; then
        install_sysinfo_daemon
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_terminal
fi
