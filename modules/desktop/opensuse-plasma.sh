#!/usr/bin/env bash
# opensuse-plasma.sh - openSUSE Plasma 6 desktop configuration
# Optional module for desktop Linux systems

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/packages.sh"
source "$SCRIPT_DIR/../../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Install rofi
PLASMA_INSTALL_ROFI="${PLASMA_INSTALL_ROFI:-true}"

# Install focus-guard
PLASMA_FOCUS_GUARD="${PLASMA_FOCUS_GUARD:-true}"

# Configure KWin
PLASMA_CONFIGURE_KWIN="${PLASMA_CONFIGURE_KWIN:-true}"

# =============================================================================
# VALIDATION
# =============================================================================

check_plasma() {
    if [[ "$DETECTED_DISTRO" != "opensuse"* ]] && ! confirm "This module is designed for openSUSE. Continue anyway?"; then
        exit 1
    fi

    # Check for Plasma
    if ! cmd_exists plasmashell; then
        log_warn "Plasma shell not detected. Some features may not work."
    fi
}

# =============================================================================
# ROFI INSTALLATION
# =============================================================================

install_rofi() {
    if [[ "$PLASMA_INSTALL_ROFI" != "true" ]]; then
        log_skip "Rofi installation disabled"
        return 0
    fi

    section "Installing Rofi"

    pkg_install_many rofi libinput-tools xinput xdotool

    # Link rofi configs
    local rofi_source="$BOOTSTRAP_DIR/linux/openSuse_plasma6/rofi"
    local rofi_target="$HOME/.config/rofi"

    if [[ -d "$rofi_source" ]]; then
        ensure_dir "$rofi_target"
        safe_symlink "$rofi_source/config.rasi" "$rofi_target/config.rasi"
        safe_symlink "$rofi_source/theme.rasi" "$rofi_target/theme.rasi"

        # Install desktop entry
        ensure_dir "$HOME/.local/share/applications"
        safe_symlink "$rofi_source/rofi-launcher.desktop" "$HOME/.local/share/applications/rofi-launcher.desktop"

        log_success "Rofi configured"
    else
        log_warn "Rofi config source not found at $rofi_source"
    fi
}

# =============================================================================
# SCRIPTS INSTALLATION
# =============================================================================

install_scripts() {
    section "Installing Plasma Scripts"

    local scripts_source="$BOOTSTRAP_DIR/linux/openSuse_plasma6/scripts"
    local scripts_target="$HOME/.local/bin"

    if [[ ! -d "$scripts_source" ]]; then
        log_warn "Scripts source not found at $scripts_source"
        return 0
    fi

    ensure_dir "$scripts_target"

    for script in "$scripts_source"/*; do
        if [[ -f "$script" ]]; then
            local script_name
            script_name="$(basename "$script")"
            safe_symlink "$script" "$scripts_target/$script_name"
            chmod +x "$scripts_target/$script_name"
        fi
    done

    log_success "Scripts installed"
}

# =============================================================================
# FOCUS GUARD SETUP
# =============================================================================

setup_focus_guard() {
    if [[ "$PLASMA_FOCUS_GUARD" != "true" ]]; then
        log_skip "Focus guard disabled"
        return 0
    fi

    section "Setting Up Focus Guard"

    # Add user to input group
    if ! groups "$USER" | grep -q input; then
        log_info "Adding $USER to input group..."
        sudo usermod -aG input "$USER"
        log_warn "Log out and back in for group membership to take effect"
    fi

    # Create autostart entry
    local autostart_dir="$HOME/.config/autostart"
    ensure_dir "$autostart_dir"

    cat > "$autostart_dir/focus-guard.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Focus Guard
Comment=Dynamic focus stealing prevention based on keyboard activity
Exec=$HOME/.local/bin/focus-guard start
Terminal=false
X-KDE-autostart-phase=2
EOF

    log_success "Focus guard autostart configured"
}

# =============================================================================
# KWIN CONFIGURATION
# =============================================================================

configure_kwin() {
    if [[ "$PLASMA_CONFIGURE_KWIN" != "true" ]]; then
        log_skip "KWin configuration disabled"
        return 0
    fi

    section "Configuring KWin"

    local kwin_source="$BOOTSTRAP_DIR/linux/openSuse_plasma6/kwin"

    if [[ ! -d "$kwin_source" ]]; then
        log_warn "KWin config source not found"
        return 0
    fi

    # Backup existing configs
    for config in kwinrc kwinrulesrc; do
        if [[ -f "$HOME/.config/$config" ]]; then
            backup_file "$HOME/.config/$config"
        fi
    done

    # Copy KWin configs (don't symlink - KWin doesn't like symlinks)
    cp "$kwin_source/kwinrc" "$HOME/.config/" 2>/dev/null || true
    cp "$kwin_source/kwinrulesrc" "$HOME/.config/" 2>/dev/null || true

    # Reload KWin
    if cmd_exists qdbus6; then
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || log_info "Could not reload KWin (may need manual reload)"
    fi

    log_success "KWin configured"
}

# =============================================================================
# SHORTCUTS CONFIGURATION
# =============================================================================

configure_shortcuts() {
    section "Configuring Global Shortcuts"

    local shortcuts_source="$BOOTSTRAP_DIR/linux/openSuse_plasma6/plasma/kglobalshortcutsrc"

    if [[ ! -f "$shortcuts_source" ]]; then
        log_warn "Shortcuts config not found"
        return 0
    fi

    # Backup and copy (KDE configs don't work well as symlinks)
    if [[ -f "$HOME/.config/kglobalshortcutsrc" ]]; then
        backup_file "$HOME/.config/kglobalshortcutsrc"
    fi

    cp "$shortcuts_source" "$HOME/.config/kglobalshortcutsrc"

    # Reload shortcuts
    if cmd_exists systemctl; then
        systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || log_info "Could not reload shortcuts"
    fi

    log_success "Shortcuts configured"
}

# =============================================================================
# MAIN
# =============================================================================

install_opensuse_plasma() {
    check_plasma
    install_rofi
    install_scripts
    setup_focus_guard
    configure_kwin
    configure_shortcuts

    # Update desktop database
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

    log_success "openSUSE Plasma 6 configuration complete"
    log_warn "Log out and back in for all changes to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_opensuse_plasma
fi
