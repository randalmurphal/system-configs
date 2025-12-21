# System Configs Bootstrap

Modular, idempotent development environment bootstrap for WSL/Linux/macOS.

## Quick Start

```bash
# Clone the repository
git clone git@github.com:randalmurphal/system-configs.git ~/repos/system-configs
cd ~/repos/system-configs

# Configure (optional - has sensible defaults)
cp options.example.conf options.conf
# Edit options.conf to customize

# Run bootstrap
./bootstrap.sh --all    # Install everything
# Or: ./bootstrap.sh    # Interactive menu
```

## What Gets Installed

| Module | Components |
|--------|------------|
| **shell** | ZSH, oh-my-zsh, plugins (autosuggestions, syntax-highlighting) |
| **terminal** | tmux, TPM (plugin manager), WezTerm config |
| **editor** | Neovim (latest), config (LazyVim/custom), Nerd Fonts |
| **languages** | mise (version manager), Python 3.12, Node.js LTS, Go, Rust |
| **tools** | bat, eza, fd, ripgrep, fzf, zoxide, delta, lazygit, gh |
| **claude** | Claude Code CLI, settings, MCP servers |
| **wsl** | WSL optimizations, clipboard, Windows interop (WSL only) |

## Usage

```bash
./bootstrap.sh              # Interactive menu
./bootstrap.sh --all        # Install everything
./bootstrap.sh -m editor    # Install specific module
./bootstrap.sh --list       # List available modules
./bootstrap.sh --update     # Update existing installation
```

## Configuration

Copy `options.example.conf` to `options.conf` and customize:

```bash
# Use your own neovim config
EDITOR_NVIM_DISTRO="github"
EDITOR_NVIM_REPO="yourusername/neovim-config"

# Python version
LANG_PYTHON_VERSION="3.12"

# Shell plugin manager: "oh-my-zsh" or "zinit"
SHELL_PLUGIN_MANAGER="oh-my-zsh"
```

See `options.example.conf` for all available options.

## Platform Support

- **Ubuntu/Debian** (apt)
- **Fedora/RHEL** (dnf)
- **Arch/Manjaro** (pacman)
- **openSUSE** (zypper)
- **macOS** (Homebrew)
- **WSL2** (apt + Windows integration)

## Repository Structure

```
system-configs/
├── bootstrap.sh          # Main entry point
├── options.example.conf  # Configuration template
├── lib/                  # Shared libraries
│   ├── common.sh         # Logging, OS detection, utilities
│   ├── packages.sh       # Package manager abstraction
│   └── symlinks.sh       # Safe symlink management
├── modules/              # Installation modules
│   ├── shell.sh          # ZSH + plugins
│   ├── terminal.sh       # tmux + WezTerm
│   ├── editor.sh         # Neovim
│   ├── languages.sh      # mise + Python/Node/Go/Rust
│   ├── tools.sh          # CLI tools
│   ├── claude.sh         # Claude Code
│   └── wsl.sh            # WSL optimizations
├── configs/              # Dotfiles (symlinked to ~/)
│   ├── shell/            # ZSH configuration
│   ├── tmux/             # tmux configuration
│   ├── wezterm/          # WezTerm + sysinfo daemon
│   └── git/              # Git configuration
└── linux/                # Platform-specific extras
    └── openSuse_plasma6/ # KDE Plasma configs (optional)
```

## Key Bindings

### Tmux (prefix: Ctrl+Space)

| Key | Action |
|-----|--------|
| `v` / `V` | Split horizontal / vertical |
| `Alt+hjkl` | Navigate panes |
| `h` / `l` | Previous / next window |
| `n` | New window |
| `g` | Open lazygit |
| `/` | Open nvim |

### Neovim (leader: Space)

| Key | Action |
|-----|--------|
| `<leader>sf` | Search files |
| `<leader>sg` | Search by grep |
| `<leader>e` | Toggle file explorer |
| `<leader>f` | Format buffer |
| `grn` | Rename symbol |
| `grd` | Go to definition |

## Modern CLI Tools

After installation, these replacements are available:

| Classic | Modern | Description |
|---------|--------|-------------|
| `cat` | `bat` | Syntax highlighting |
| `ls` | `eza` | Better file listing |
| `find` | `fd` | Faster file search |
| `grep` | `rg` | Faster text search |
| `cd` | `z` | Smart directory jumping (zoxide) |

## Notes

- All operations are **idempotent** - safe to run multiple times
- Existing configs are **backed up** before overwriting
- Neovim plugins **auto-install** on first launch
- WSL changes require `wsl --shutdown` to take effect
