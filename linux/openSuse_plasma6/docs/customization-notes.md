# Customization Notes

Technical details and learnings from setting up this configuration.

## Rofi vs KRunner

**Why Rofi instead of KRunner:**
- KRunner has a [known bug (377914)](https://bugs.kde.org/show_bug.cgi?id=377914) where High/Extreme focus stealing prevention blocks it
- KRunner doesn't properly follow focused window on multi-monitor setups
- KRunner is a special Plasma overlay that ignores window rules
- Rofi respects monitor focus with `-m -4` flag

## Focus Stealing Prevention

**Levels:**
| Level | Value | Behavior |
|-------|-------|----------|
| None | 0 | All windows always get focus |
| Low | 1 | Allow uncertain windows |
| Medium | 2 | Default, balanced |
| High | 3 | Only current app's windows (breaks KRunner) |
| Extreme | 4 | User must explicitly activate |

**Config location:** `~/.config/kwinrc` under `[Windows]`
```ini
FocusStealingPreventionLevel=2
```

**Focus Guard Script:**
Dynamic approach - switches to Extreme while typing, Low when idle.
Requires user to be in `input` group to monitor keyboard events.

## KWin Window Rules

**File:** `~/.config/kwinrulesrc`

**Rule format:**
```ini
[1]
Description=Rule Name
wmclass=window-class
wmclassmatch=1          # 0=Exact, 1=Substring, 2=Regex
fsplevel=0              # Focus stealing level for this window
fsplevelrule=3          # 3=Force
```

**Blur rule (doesn't work reliably with rofi on X11):**
```ini
blur=true
blurrule=3
```

## Rofi Theming

**Config location:** `~/.config/rofi/`

**Key settings in config.rasi:**
```css
m: "-4";                    /* Monitor with focused window */
matching: "fuzzy";          /* Fuzzy search */
combi-modes: "drun,filebrowser";  /* Combined search */
kb-cancel: "Escape,Alt+space";    /* Close with Alt+Space */
```

**Theme transparency:**
```css
bg: #20202099;  /* Last 2 digits = alpha (99 = 60% opacity) */
```

**Alpha values:**
| Hex | Opacity |
|-----|---------|
| ff | 100% |
| cc | 80% |
| 99 | 60% |
| 80 | 50% |
| 60 | 37% |
| 00 | 0% |

## Multi-Monitor Setup

**Monitor layout (example):**
- DP-0: LG ULTRAGEAR (left, screen 0)
- DP-4: ASUS VG27WQ1B (center, screen 1, primary)
- HDMI-0: HP 27h (right, screen 2)

**Screen focus settings:**
```ini
[Windows]
ActiveMouseScreen=true
SeparateScreenFocus=true
```

**Panel config:** `~/.config/plasma-org.kde.plasma.desktop-appletsrc`

## Blur on X11

KWin blur doesn't work well with rofi on X11 because:
1. Rofi doesn't request blur hint by default
2. Window rules blur doesn't apply to popup-style windows
3. `_KDE_NET_WM_BLUR_BEHIND_REGION` hint needs to be set manually

**Workaround attempted (didn't work):**
```bash
xprop -id "$wid" -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0
```

**Solution:** Accept no blur, use semi-transparent background instead.

## Keyboard Shortcuts

**Meta key binding:** `~/.config/kwinrc`
```ini
[ModifierOnlyShortcuts]
Meta=org.kde.krunner,/App,,toggleDisplay
```

**Custom shortcuts:** `~/.config/kglobalshortcutsrc`

**Reload shortcuts:**
```bash
systemctl --user restart plasma-kglobalaccel.service
```

## Plasma 5 vs Plasma 6 Differences

- Third-party widgets from Plasma 5 don't work in Plasma 6
- `kpackagetool5` → `kpackagetool6`
- `qdbus` → `qdbus6`
- `kwriteconfig5` → `kwriteconfig6`
- khotkeys replaced with different system in Plasma 6
