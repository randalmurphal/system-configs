# WezTerm Configuration

GPU-accelerated terminal emulator config, replacing tmux for multiplexing.

## Setup

### Windows (with WSL)

WezTerm runs on Windows but connects to WSL. The config lives in WSL and is symlinked to Windows.

1. **Delete existing config** (if any):
   ```powershell
   Remove-Item "C:\Users\rmurphy\.wezterm.lua" -Force
   ```

2. **Create symlink** (PowerShell as Administrator):
   ```powershell
   New-Item -ItemType SymbolicLink -Path "C:\Users\rmurphy\.wezterm.lua" -Target "\\wsl$\Ubuntu-24.04\home\rmurphy\repos\system-configs\wezterm_configs\.wezterm.lua"
   ```

3. **Verify**: Open WezTerm, should connect to WSL automatically.

### Linux Native

```bash
ln -sf ~/repos/system-configs/wezterm_configs/.wezterm.lua ~/.wezterm.lua
```

## Key Bindings

Leader key: `Ctrl+Space` (1 second timeout)

### Navigation (No Leader)

| Binding | Action |
|---------|--------|
| `Alt+h/j/k/l` | Navigate panes |
| `Alt+Shift+h/l` | Previous/next tab |
| `Ctrl+Shift+C` | Copy selection |
| `Ctrl+Shift+V` | Paste |

### Leader Commands

| Binding | Action |
|---------|--------|
| `Leader + v` | Split right |
| `Leader + V` | Split down |
| `Leader + x` | Close pane |
| `Leader + X` | Close tab |
| `Leader + n` | New tab |
| `Leader + 1-9` | Switch to tab N |
| `Leader + z` | Zoom/unzoom pane |
| `Leader + a` | Break pane to new tab |
| `Leader + b` | Bring pane from another tab |
| `Leader + p` | Swap pane positions (picker) |
| `Leader + {` | Rotate panes counter-clockwise |
| `Leader + }` | Rotate panes clockwise |
| `Leader + k` | Enter copy mode |
| `Leader + f` | Search scrollback |
| `Leader + g` | Open nvim with telescope grep |
| `Leader + Space` | Quick select (URLs, paths) |
| `Leader + r` | Reload config |
| `Leader + ?` | Debug overlay |
| `Leader + s` | Save session |
| `Leader + R` | Restore session (picker) |

### Copy Mode (vim-style)

| Binding | Action |
|---------|--------|
| `h/j/k/l` | Move cursor |
| `w/b/e` | Word movement |
| `0/$` | Line start/end |
| `g/G` | Top/bottom of scrollback |
| `Ctrl+u/d` | Page up/down |
| `v/V/Ctrl+v` | Selection modes |
| `y` | Copy (stay in copy mode) |
| `Enter` | Copy and exit |
| `q/Escape` | Exit copy mode |

## Plugins

- **resurrect.wezterm**: Session persistence (auto-saves every 5 minutes)

## Theme

Dark purple theme matching nvim setup:
- Background: `#050505`
- Primary purple: `#9d4edd`
- Inactive panes: 40% darker
