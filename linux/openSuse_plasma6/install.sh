#!/bin/bash
# openSUSE Plasma 6 Configuration Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== openSUSE Plasma 6 Config Installer ==="
echo ""

# Check if running on openSUSE
if ! grep -q "openSUSE" /etc/os-release 2>/dev/null; then
    echo "Warning: This doesn't appear to be openSUSE. Continue anyway? (y/n)"
    read -r response
    [[ "$response" != "y" ]] && exit 1
fi

# Install packages
echo "Installing required packages..."
sudo zypper install -y rofi rofi-calc libinput-tools xinput xdotool

# Add to input group
echo "Adding user to input group..."
sudo usermod -aG input "$USER"

# Create directories
echo "Creating directories..."
mkdir -p ~/.config/rofi
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.config/autostart

# Install rofi
echo "Installing rofi configs..."
cp "$SCRIPT_DIR/rofi/config.rasi" ~/.config/rofi/
cp "$SCRIPT_DIR/rofi/theme.rasi" ~/.config/rofi/
cp "$SCRIPT_DIR/rofi/rofi-launcher.desktop" ~/.local/share/applications/

# Install scripts
echo "Installing scripts..."
cp "$SCRIPT_DIR/scripts/rofi-toggle" ~/.local/bin/
cp "$SCRIPT_DIR/scripts/focus-guard" ~/.local/bin/
cp "$SCRIPT_DIR/scripts/plasma-panel-helper" ~/.local/bin/
chmod +x ~/.local/bin/rofi-toggle
chmod +x ~/.local/bin/focus-guard
chmod +x ~/.local/bin/plasma-panel-helper

# Install KWin configs (backup first)
echo "Installing KWin configs..."
[[ -f ~/.config/kwinrc ]] && cp ~/.config/kwinrc ~/.config/kwinrc.backup
[[ -f ~/.config/kwinrulesrc ]] && cp ~/.config/kwinrulesrc ~/.config/kwinrulesrc.backup
cp "$SCRIPT_DIR/kwin/kwinrc" ~/.config/
cp "$SCRIPT_DIR/kwin/kwinrulesrc" ~/.config/

# Focus guard autostart
echo "Setting up focus-guard autostart..."
cat > ~/.config/autostart/focus-guard.desktop << EOF
[Desktop Entry]
Type=Application
Name=Focus Guard
Comment=Dynamic focus stealing prevention based on keyboard activity
Exec=$HOME/.local/bin/focus-guard start
Terminal=false
X-KDE-autostart-phase=2
EOF

# Reload KWin
echo "Reloading KWin..."
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || echo "Could not reload KWin (may need manual reload)"

# Reload shortcuts
echo "Reloading shortcuts..."
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || echo "Could not reload shortcuts (may need re-login)"

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null || true

echo ""
echo "=== Installation Complete ==="
echo ""
echo "NOTE: You need to LOG OUT and back in for:"
echo "  - Input group membership (for focus-guard)"
echo "  - Shortcut changes to fully apply"
echo ""
echo "Test rofi with: Alt+Space"
echo ""
