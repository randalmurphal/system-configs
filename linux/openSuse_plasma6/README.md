# openSUSE Plasma 6 Configuration

Personal system configuration for openSUSE with KDE Plasma 6.

## Quick Install

```bash
# Install required packages
sudo zypper install rofi rofi-calc libinput-tools xinput xdotool

# Add user to input group (for focus-guard)
sudo usermod -aG input $USER

# Run the install script
./install.sh
```

## What's Included

### Rofi Launcher (Spotlight-style)
macOS Spotlight-inspired application launcher with:
- **Alt+Space** to open/close
- Combined app + file search
- Semi-transparent dark theme with white border
- Positioned in upper-center of screen
- Empty until you start typing

**Files:**
- `rofi/config.rasi` - Main configuration
- `rofi/theme.rasi` - Visual styling
- `rofi/rofi-launcher.desktop` - Desktop entry for shortcuts

### KWin Window Manager
- Focus stealing prevention (Medium level)
- Window rules for Chrome, Firefox (always focus)
- Blur effect enabled

**Files:**
- `kwin/kwinrc` - Main KWin settings
- `kwin/kwinrulesrc` - Window-specific rules

### Custom Scripts

| Script | Purpose |
|--------|---------|
| `scripts/rofi-toggle` | Toggle rofi open/closed with Alt+Space |
| `scripts/focus-guard` | Dynamic focus stealing prevention while typing |
| `scripts/plasma-panel-helper` | Manage panel configs across monitors |

### Keyboard Shortcuts
- **Alt+Space** - Rofi launcher
- **Meta+Up** - Maximize window
- Other shortcuts in `plasma/kglobalshortcutsrc`

## Directory Structure

```
openSuse_plasma6/
├── README.md
├── install.sh
├── rofi/
│   ├── config.rasi
│   ├── theme.rasi
│   └── rofi-launcher.desktop
├── kwin/
│   ├── kwinrc
│   └── kwinrulesrc
├── plasma/
│   └── kglobalshortcutsrc
├── scripts/
│   ├── rofi-toggle
│   ├── focus-guard
│   └── plasma-panel-helper
└── docs/
    └── customization-notes.md
```

## Manual Setup Steps

### 1. Rofi
```bash
mkdir -p ~/.config/rofi ~/.local/bin
cp rofi/config.rasi rofi/theme.rasi ~/.config/rofi/
cp rofi/rofi-launcher.desktop ~/.local/share/applications/
cp scripts/rofi-toggle ~/.local/bin/
chmod +x ~/.local/bin/rofi-toggle
```

### 2. KWin
```bash
cp kwin/kwinrc ~/.config/
cp kwin/kwinrulesrc ~/.config/
qdbus6 org.kde.KWin /KWin reconfigure
```

### 3. Focus Guard (Optional)
```bash
cp scripts/focus-guard ~/.local/bin/
chmod +x ~/.local/bin/focus-guard
# Add to autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/focus-guard.desktop << EOF
[Desktop Entry]
Type=Application
Name=Focus Guard
Exec=$HOME/.local/bin/focus-guard start
Terminal=false
EOF
```

### 4. Reload Settings
```bash
# Reload KWin
qdbus6 org.kde.KWin /KWin reconfigure

# Restart kglobalaccel for shortcuts
systemctl --user restart plasma-kglobalaccel.service
```

## Customization

### Rofi Theme Colors
Edit `~/.config/rofi/theme.rasi`:
```css
bg: #20202099;          /* Background (60% opacity) */
bg-selected: #0a84ff;   /* Selection highlight (macOS blue) */
fg: #ffffff;            /* Text color */
border-color: #ffffff55; /* Border (subtle white) */
```

### Rofi Size/Position
Edit `~/.config/rofi/theme.rasi`:
```css
window {
    width: 500px;
    border-radius: 24px;
    y-offset: 25%;       /* 25% from top = center of top half */
}
```

## Multi-Monitor Notes

- Rofi appears on the monitor with the focused window (`m: "-4"`)
- Panel configs can be copied between monitors using `plasma-panel-helper`
- KRunner has known issues with multi-monitor focus (that's why we use rofi)

## Troubleshooting

### Rofi not opening
```bash
# Test directly
rofi -show combi

# Check if shortcut is registered
grep -r "Alt+Space" ~/.config/kglobalshortcutsrc
```

### Focus guard not working
```bash
# Check if in input group
groups | grep input

# If not, add and re-login
sudo usermod -aG input $USER
```

### Shortcuts not working
```bash
systemctl --user restart plasma-kglobalaccel.service
```
