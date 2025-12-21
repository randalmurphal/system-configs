#!/usr/bin/env bash
# wsl.sh - WSL-specific optimizations and configuration

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Configure wsl.conf
WSL_CONFIGURE_CONF="${WSL_CONFIGURE_CONF:-true}"

# Setup Windows interop
WSL_WINDOWS_INTEROP="${WSL_WINDOWS_INTEROP:-true}"

# Configure systemd
WSL_SYSTEMD="${WSL_SYSTEMD:-true}"

# Memory limit (in GB, 0 = no limit)
WSL_MEMORY_LIMIT="${WSL_MEMORY_LIMIT:-0}"

# Swap size (in GB, 0 = no swap)
WSL_SWAP_SIZE="${WSL_SWAP_SIZE:-0}"

# =============================================================================
# WSL DETECTION
# =============================================================================

check_wsl() {
    if [[ "$IS_WSL" != "1" ]]; then
        log_error "This module is only for WSL environments"
        exit 1
    fi

    log_info "WSL environment detected"

    # Detect WSL version
    local wsl_version="1"
    if [[ -f /proc/version ]] && grep -qi "microsoft-standard-WSL2" /proc/version; then
        wsl_version="2"
    fi
    log_info "WSL version: $wsl_version"
}

# =============================================================================
# WSL.CONF CONFIGURATION
# =============================================================================

configure_wsl_conf() {
    if [[ "$WSL_CONFIGURE_CONF" != "true" ]]; then
        log_skip "wsl.conf configuration disabled"
        return 0
    fi

    section "Configuring /etc/wsl.conf"

    local wsl_conf="/etc/wsl.conf"

    # Check if already configured
    if [[ -f "$wsl_conf" ]] && grep -q "# Managed by system-configs" "$wsl_conf"; then
        log_skip "wsl.conf already managed"
        return 0
    fi

    # Backup existing
    if [[ -f "$wsl_conf" ]]; then
        sudo cp "$wsl_conf" "${wsl_conf}.backup.$(date +%Y%m%d)"
    fi

    log_info "Creating wsl.conf..."
    sudo tee "$wsl_conf" > /dev/null << EOF
# Managed by system-configs
# Changes require WSL restart: wsl --shutdown

[boot]
# Enable systemd
systemd=$([[ "$WSL_SYSTEMD" == "true" ]] && echo "true" || echo "false")

[automount]
# Mount Windows drives at /mnt/
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"

# Mount network drives
mountFsTab = true

[interop]
# Enable Windows interop (run .exe from Linux)
enabled = $([[ "$WSL_WINDOWS_INTEROP" == "true" ]] && echo "true" || echo "false")
appendWindowsPath = $([[ "$WSL_WINDOWS_INTEROP" == "true" ]] && echo "true" || echo "false")

[network]
# Generate /etc/hosts
generateHosts = true
# Generate /etc/resolv.conf
generateResolvConf = true

[user]
# Default user
default = $USER
EOF

    log_success "wsl.conf configured"
    log_warn "Restart WSL for changes: wsl --shutdown"
}

# =============================================================================
# .WSLCONFIG (Windows-side configuration)
# =============================================================================

configure_wslconfig() {
    section "Configuring .wslconfig"

    # Get Windows home directory
    local win_home
    win_home="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"

    if [[ -z "$win_home" || ! -d "$win_home" ]]; then
        log_warn "Could not detect Windows home directory"
        return 1
    fi

    local wslconfig="$win_home/.wslconfig"

    if [[ -f "$wslconfig" ]]; then
        log_info "Existing .wslconfig found at $wslconfig"
        if ! confirm "Update .wslconfig?"; then
            log_skip ".wslconfig update skipped"
            return 0
        fi
    fi

    log_info "Creating .wslconfig..."

    local memory_setting=""
    local swap_setting=""

    if [[ "$WSL_MEMORY_LIMIT" != "0" ]]; then
        memory_setting="memory=${WSL_MEMORY_LIMIT}GB"
    fi

    if [[ "$WSL_SWAP_SIZE" != "0" ]]; then
        swap_setting="swap=${WSL_SWAP_SIZE}GB"
    fi

    cat > "$wslconfig" << EOF
# WSL2 Configuration
# Changes require WSL restart: wsl --shutdown

[wsl2]
# Limits VM memory (comment out for default = 50% of host RAM)
${memory_setting:-# memory=8GB}

# Swap size (comment out for default = 25% of host RAM)
${swap_setting:-# swap=0}

# Number of processors
# processors=4

# Enable nested virtualization
nestedVirtualization=true

# Turn on output console showing contents of dmesg
# debugConsole=true

[experimental]
# Automatically reclaim cached memory
autoMemoryReclaim=gradual

# Sparse VHD (reclaim disk space)
sparseVhd=true
EOF

    log_success ".wslconfig created at $wslconfig"
    log_warn "Restart WSL for changes: wsl --shutdown"
}

# =============================================================================
# WINDOWS PATH INTEGRATION
# =============================================================================

configure_windows_path() {
    if [[ "$WSL_WINDOWS_INTEROP" != "true" ]]; then
        log_skip "Windows interop disabled"
        return 0
    fi

    section "Configuring Windows PATH"

    # Create wrapper scripts for common Windows commands
    local bin_dir="$HOME/.local/bin"
    ensure_dir "$bin_dir"

    # Windows Terminal
    if ! cmd_exists wt; then
        cat > "$bin_dir/wt" << 'EOF'
#!/bin/bash
wt.exe "$@"
EOF
        chmod +x "$bin_dir/wt"
    fi

    # VS Code
    if ! cmd_exists code; then
        cat > "$bin_dir/code" << 'EOF'
#!/bin/bash
code.exe "$@"
EOF
        chmod +x "$bin_dir/code"
    fi

    # Windows Explorer
    cat > "$bin_dir/explorer" << 'EOF'
#!/bin/bash
if [[ $# -eq 0 ]]; then
    explorer.exe .
else
    explorer.exe "$(wslpath -w "$1")"
fi
EOF
    chmod +x "$bin_dir/explorer"

    # Open command (like macOS)
    cat > "$bin_dir/open" << 'EOF'
#!/bin/bash
if [[ $# -eq 0 ]]; then
    explorer.exe .
else
    cmd.exe /c start "" "$(wslpath -w "$1")"
fi
EOF
    chmod +x "$bin_dir/open"

    log_success "Windows command wrappers created"
}

# =============================================================================
# CLIPBOARD INTEGRATION
# =============================================================================

configure_clipboard() {
    section "Configuring Clipboard"

    local bin_dir="$HOME/.local/bin"
    ensure_dir "$bin_dir"

    # Create pbcopy/pbpaste equivalents using Windows clipboard
    cat > "$bin_dir/pbcopy" << 'EOF'
#!/bin/bash
cat | clip.exe
EOF
    chmod +x "$bin_dir/pbcopy"

    cat > "$bin_dir/pbpaste" << 'EOF'
#!/bin/bash
powershell.exe -command "Get-Clipboard" | tr -d '\r'
EOF
    chmod +x "$bin_dir/pbpaste"

    # Also create xclip wrapper for compatibility
    if ! cmd_exists xclip; then
        cat > "$bin_dir/xclip" << 'EOF'
#!/bin/bash
if [[ "$1" == "-selection" && "$2" == "clipboard" && "$3" == "-o" ]]; then
    powershell.exe -command "Get-Clipboard" | tr -d '\r'
elif [[ "$1" == "-selection" && "$2" == "clipboard" ]]; then
    cat | clip.exe
else
    cat | clip.exe
fi
EOF
        chmod +x "$bin_dir/xclip"
    fi

    log_success "Clipboard integration configured"
}

# =============================================================================
# PERFORMANCE OPTIMIZATIONS
# =============================================================================

configure_performance() {
    section "Configuring Performance Optimizations"

    # Git performance in WSL
    if cmd_exists git; then
        # Improve git performance in WSL
        git config --global core.fscache true
        git config --global core.preloadindex true
        git config --global core.untrackedCache true

        # Disable stat cache for cross-filesystem access
        git config --global core.checkStat minimal

        log_success "Git WSL optimizations applied"
    fi

    # npm config for faster installs
    if cmd_exists npm; then
        # Use Linux filesystem for npm cache
        npm config set cache "$HOME/.npm" 2>/dev/null || true
        log_success "npm cache configured for Linux filesystem"
    fi

    log_info "Tip: Keep projects on Linux filesystem (/home) for best performance"
    log_info "Avoid /mnt/c for development work"
}

# =============================================================================
# DOCKER/NERDCTL CONFIGURATION
# =============================================================================

configure_containers() {
    section "Configuring Container Runtime"

    # Check if Docker Desktop is available
    if cmd_exists docker.exe; then
        log_info "Docker Desktop detected"

        # Create docker wrapper if not using Docker Desktop's integration
        if ! cmd_exists docker; then
            local bin_dir="$HOME/.local/bin"
            ensure_dir "$bin_dir"

            cat > "$bin_dir/docker" << 'EOF'
#!/bin/bash
docker.exe "$@"
EOF
            chmod +x "$bin_dir/docker"
            log_success "Created docker wrapper"
        fi
    else
        log_info "Docker Desktop not detected"
        log_info "Consider installing Docker Desktop for Windows or nerdctl"
    fi
}

# =============================================================================
# SHELL OPTIMIZATIONS
# =============================================================================

configure_shell_wsl() {
    section "Configuring Shell for WSL"

    # Add WSL-specific settings to user's local config (not tracked in git)
    local wsl_config_dir="$HOME/.config/zsh"
    local wsl_config="$wsl_config_dir/wsl.zsh"

    ensure_dir "$wsl_config_dir"

    if [[ -f "$wsl_config" ]]; then
        log_skip "WSL shell config already exists at $wsl_config"
        return 0
    fi

    cat > "$wsl_config" << 'EOF'
# WSL-specific ZSH configuration
# Auto-generated by system-configs bootstrap

# Ensure ~/.local/bin is in PATH (for our wrappers)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Windows home directory (cached for performance)
if [[ -z "$WIN_HOME" ]]; then
    export WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"
fi

# Aliases for Windows integration
alias winpath='wslpath -w'
alias linpath='wslpath -u'
[[ -n "$WIN_HOME" ]] && alias cdwin='cd "$WIN_HOME"'

# Browser (use Windows default browser)
export BROWSER='wslview'

# Docker host (if using Docker Desktop)
# export DOCKER_HOST="tcp://localhost:2375"

# Fix for slow shell startup with Windows PATH
# Uncomment if shell is slow:
# export PATH="${PATH//:\/mnt\/c*/}"
EOF

    log_success "WSL shell config created at $wsl_config"

    # Add source line to user's .zshrc if not already present
    local zshrc="$HOME/.zshrc"
    local source_line="[[ -f \"$wsl_config\" ]] && source \"$wsl_config\""

    if [[ -f "$zshrc" ]] && ! grep -q "wsl.zsh" "$zshrc"; then
        # Only append if .zshrc is not a symlink (don't modify tracked files)
        if [[ ! -L "$zshrc" ]]; then
            echo "" >> "$zshrc"
            echo "# WSL-specific configuration" >> "$zshrc"
            echo "$source_line" >> "$zshrc"
            log_success "Added WSL config source to .zshrc"
        else
            log_info "Add to your shell config: source $wsl_config"
        fi
    fi
}

# =============================================================================
# MAIN
# =============================================================================

install_wsl() {
    check_wsl
    configure_wsl_conf
    configure_wslconfig
    configure_windows_path
    configure_clipboard
    configure_performance
    configure_containers
    configure_shell_wsl

    log_success "WSL configuration complete"
    log_warn "Run 'wsl --shutdown' in Windows Terminal to apply changes"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_wsl
fi
