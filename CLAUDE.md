# system-configs - Development Environment Bootstrap

**Purpose**: Modular, idempotent bootstrap system for WSL/Linux/macOS development environments.

---

## Quick Start

```bash
git clone git@github.com:randalmurphal/system-configs.git ~/repos/system-configs
cd ~/repos/system-configs
cp options.example.conf options.conf  # Customize settings
./bootstrap.sh --all                   # Install everything
# Or: ./bootstrap.sh                   # Interactive menu
```

---

## Architecture

```
system-configs/
├── bootstrap.sh          # Main entry point
├── options.conf          # User config (gitignored)
├── options.example.conf  # Config template
├── lib/                  # Shared utilities (see lib/CLAUDE.md)
├── modules/              # Installation modules (see modules/CLAUDE.md)
├── configs/              # Dotfiles to symlink (see configs/CLAUDE.md)
└── linux/                # Platform-specific extras (openSUSE Plasma)
```

---

## Modules

| Module | What It Does | Key Config |
|--------|--------------|------------|
| `shell` | ZSH + oh-my-zsh/zinit + plugins | `SHELL_PLUGIN_MANAGER` |
| `terminal` | tmux + TPM + WezTerm | `TERMINAL_INSTALL_TPM` |
| `editor` | Neovim + config (LazyVim/GitHub/etc) | `EDITOR_NVIM_DISTRO`, `EDITOR_NVIM_REPO` |
| `languages` | mise + Python 3.12 + Node LTS + Go + Rust | `LANG_PYTHON_VERSION` |
| `tools` | Modern CLI (bat, fd, ripgrep, fzf, eza, zoxide) | `TOOLS_ENHANCED` |
| `claude` | Claude Code CLI + settings + MCP | `CLAUDE_INSTALL` |
| `wsl` | WSL optimizations, clipboard, Windows interop | `WSL_SYSTEMD` |

---

## Platform Support

| Platform | Package Manager | Tested |
|----------|-----------------|--------|
| Ubuntu/Debian | apt | Yes |
| Fedora/RHEL | dnf | Yes |
| Arch/Manjaro | pacman | Yes |
| openSUSE | zypper | Yes |
| macOS | Homebrew | Yes |
| WSL2 | apt (+ Windows integration) | Yes |

WSL gets additional: clipboard integration, Windows PATH wrappers, `/etc/wsl.conf` setup.

---

## Usage

```bash
# Interactive mode
./bootstrap.sh

# Install everything
./bootstrap.sh --all

# Specific module
./bootstrap.sh -m editor
./bootstrap.sh -m languages

# List available modules
./bootstrap.sh --list

# Custom config file
./bootstrap.sh -c myoptions.conf --all

# Update existing installation
./bootstrap.sh --update
```

---

## Configuration

Copy `options.example.conf` to `options.conf` (gitignored) and customize:

```bash
# Neovim from your own repo
EDITOR_NVIM_DISTRO="github"
EDITOR_NVIM_REPO="yourusername/neovim-config"

# Languages
LANG_PYTHON_VERSION="3.12"
LANG_NODE_VERSION="lts"

# Shell
SHELL_PLUGIN_MANAGER="oh-my-zsh"
SHELL_PLUGINS="zsh-autosuggestions zsh-syntax-highlighting"
```

All options can also be set via environment variables.

---

## Key Design Principles

1. **Idempotent**: Run multiple times safely - skips already-installed items
2. **Modular**: Install only what you need
3. **Configurable**: All options exposed via `options.conf`
4. **Cross-platform**: Same interface across Linux distros and macOS
5. **Non-destructive**: Backs up existing configs before overwriting

---

## Development

### Adding a Module

1. Create `modules/mymodule.sh` (follow `modules/CLAUDE.md` pattern)
2. Add options to `options.example.conf`
3. Register in `bootstrap.sh` (`MODULES` array + `run_module` case)

### Adding Package Mappings

Edit `lib/packages.sh` `PACKAGE_MAP`:
```bash
["mypackage"]="apt:mypackage,brew:mypackage,dnf:mypackage,zypper:mypackage,pacman:mypackage"
```

### Testing

```bash
./bootstrap.sh -m shell     # Test single module
DEBUG=1 ./bootstrap.sh      # Verbose output
```

---

## File Locations After Install

| Config | Location |
|--------|----------|
| ZSH | `~/.zshrc` → `configs/shell/.zshrc` |
| Tmux | `~/.tmux.conf` → `configs/tmux/.tmux.conf` |
| WezTerm | `~/.wezterm.lua` → `configs/wezterm/.wezterm.lua` |
| Neovim | `~/.config/nvim/` (cloned or symlinked) |
| mise | `~/.local/bin/mise`, `~/.config/mise/` |
| Claude | `~/.claude/settings.json` |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied | Run with `sudo` only when prompted |
| Package not found | Run `./bootstrap.sh -m tools` first for dependencies |
| Neovim too old | `editor.sh` auto-installs AppImage on Ubuntu |
| mise not found after install | Restart shell or `source ~/.zshrc` |
| WSL changes not applied | Run `wsl --shutdown` in Windows Terminal |
