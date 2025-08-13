# Tmux Plugins Installation Guide

## Required Plugins

### Plugin Manager
- **tpm** (Tmux Plugin Manager)
  - Repository: `tmux-plugins/tpm`
  - Purpose: Manages all other plugins

### System Monitoring
- **tmux-cpu** - CPU percentage display
  - Repository: `tmux-plugins/tmux-cpu`
  - Provides: `#{cpu_percentage}`

- **tmux-net-speed** - Network speed display  
  - Repository: `tmux-plugins/tmux-net-speed`
  - Provides: `#{download_speed}`, `#{upload_speed}`

- **tmux-online-status** - Online/offline indicator
  - Repository: `tmux-plugins/tmux-online-status`
  - Provides: `#{online_status}`

### Session Management
- **tmux-resurrect** - Save/restore sessions
  - Repository: `tmux-plugins/tmux-resurrect`
  - Purpose: Manual session save/restore

- **tmux-continuum** - Automatic session save/restore
  - Repository: `tmux-plugins/tmux-continuum`
  - Purpose: Auto-saves sessions every 15 minutes

- **tmux-sessionist** - Session management shortcuts
  - Repository: `tmux-plugins/tmux-sessionist`
  - Purpose: Enhanced session operations

- **t-smart-tmux-session-manager** - Smart session switching
  - Repository: `joshmedeski/t-smart-tmux-session-manager`
  - Purpose: Intelligent session management

### Workflow Enhancement
- **tmux-yank** - Copy to system clipboard
  - Repository: `tmux-plugins/tmux-yank`
  - Purpose: Better copy/paste integration

- **tmux-open** - Open files/URLs from tmux
  - Repository: `tmux-plugins/tmux-open`
  - Purpose: Quick file/URL opening

- **tmux-copycat** - Enhanced search and copy
  - Repository: `tmux-plugins/tmux-copycat`
  - Purpose: Better text searching and copying

## Installation Commands

### 1. Install TPM (Plugin Manager)
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 2. Add plugins to tmux.conf
Add these lines to your `~/.tmux.conf`:

```bash
# Plugin manager and auto-restore
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# System monitoring plugins
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-net-speed'
set -g @plugin 'tmux-plugins/tmux-online-status'

# Workflow plugins
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'tmux-plugins/tmux-copycat'

# Session management plugins
set -g @plugin 'tmux-plugins/tmux-sessionist'
set -g @plugin 'joshmedeski/t-smart-tmux-session-manager'

# Auto-save every 15 minutes
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

### 3. Install All Plugins
```bash
# Reload tmux config
tmux source-file ~/.tmux.conf

# Install plugins (press prefix + I inside tmux)
# Or run this command:
~/.tmux/plugins/tpm/scripts/install_plugins.sh
```

### 4. One-Command Setup
```bash
# Complete setup in one go:
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \
~/.tmux/plugins/tpm/scripts/install_plugins.sh && \
tmux source-file ~/.tmux.conf
```

## Plugin Controls (Inside Tmux)

- **Prefix + I** - Install new plugins
- **Prefix + U** - Update plugins  
- **Prefix + Alt + u** - Uninstall plugins not in config

## Status Bar Variables Used

These plugins provide the variables used in the status bar:
- `#{cpu_percentage}` - CPU usage percentage
- `#{download_speed}` / `#{upload_speed}` - Network speeds
- `#{online_status}` - Connection status indicator

---
*Auto-generated plugin reference - Last updated: $(date '+%Y-%m-%d %H:%M')*