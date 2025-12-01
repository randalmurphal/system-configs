# Randy's System Configuration

Personal development environment configurations for Linux/macOS systems.

## Quick Setup (New System)

```bash
# Clone this repository
git clone https://github.com/randalmurphal/system-configs.git
cd system-configs

# Run the automated setup script
./setup-system.sh
```

The setup script will prompt you to select which components to install:
- **System packages** - git, tmux, neovim, modern CLI tools (bat, ripgrep, fzf, etc.)
- **SSH key** - Create or use existing SSH key for GitHub
- **Git config** - Global git user settings
- **Shell config** - Bash or Zsh with oh-my-zsh
- **Tmux** - Terminal multiplexer with custom theme
- **Neovim** - Full IDE-like configuration (cloned from separate repo)
- **Nerd Font** - Hack Nerd Font for terminal icons

All components are optional and can be skipped.

## Neovim Configuration

The Neovim configuration lives in its own repository:
- **Default repo**: `git@github.com:randalmurphal/neovim-config.git`
- **Destination**: `~/.config/nvim`

Features:
- Kickstart.nvim-based with lazy.nvim plugin manager
- Dark purple theme matching tmux/Ghostty
- LSP support: Python (pyright + ruff), Rust, Go, TypeScript
- Treesitter syntax highlighting
- Telescope fuzzy finder
- nvim-tree file explorer
- Bufferline tabs
- Lualine statusline
- Auto-save, persistence, git integration

The setup script will clone this repo automatically, or you can do it manually:
```bash
git clone git@github.com:randalmurphal/neovim-config.git ~/.config/nvim
```

## Manual Setup

### Tmux Configuration
```bash
# Copy tmux configuration
cp tmux_configs/.tmux.conf ~/.tmux.conf

# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Start tmux and install plugins
tmux
# Press Ctrl+Space + I to install plugins
```

### Shell Configuration
```bash
# For Bash
cat bash_configs/.bashrc >> ~/.bashrc
source ~/.bashrc

# For Zsh
cat zsh_configs/.zshrc >> ~/.zshrc
source ~/.zshrc
```

### Python Development
```bash
# Copy Python configurations
cp ruff.toml ~/.config/ruff/pyproject.toml  # or set RUFF_CONFIG env var
cp pyrightconfig.json ~/your-project/

# Install Python tools
pip install ruff black isort pyright
```

## Key Features

### Tmux (prefix: Ctrl+Space)

| Keybinding | Action |
|------------|--------|
| `v` / `V` | Split horizontal / vertical |
| `Alt+hjkl` | Navigate panes |
| `h` / `l` | Previous / next window |
| `H/J/K/L` | Resize panes |
| `n` | New window |
| `s` | Save session (resurrect) |
| `k` | Enter copy mode |
| `f` | fzf file finder |
| `/` | Open nvim in current dir |
| `g` | Open lazygit |
| `Q/W/E` | Cheat sheet popups |

Theme: Dark purple (#9d4edd) matching nvim/Ghostty.

### Neovim (leader: Space)

| Keybinding | Action |
|------------|--------|
| `<leader>sf` | Search files |
| `<leader>sg` | Search by grep |
| `<leader>e` | Toggle file explorer |
| `<leader>1-9` | Jump to buffer |
| `Shift+h/l` | Previous/next buffer |
| `<leader>x` | Close buffer |
| `<leader>\\` | Vertical split |
| `<leader>-` | Horizontal split |
| `Ctrl+hjkl` | Navigate splits |
| `grn` | Rename symbol |
| `grd` | Go to definition |
| `grr` | Find references |
| `<leader>f` | Format buffer |
| `<leader>gb` | Git blame line |

### Modern CLI Tool Replacements
- `bat` instead of `cat` (syntax highlighting)
- `fd` instead of `find` (faster file search)
- `rg` instead of `grep` (faster text search)
- `htop` instead of `top` (better process viewer)
- `zoxide` for smart directory jumping (`z <path>`)

## Repository Structure

```
system-configs/
├── bash_configs/
│   └── .bashrc              # Bash aliases, functions, environment
├── zsh_configs/
│   └── .zshrc               # Zsh configuration with oh-my-zsh
├── tmux_configs/
│   ├── .tmux.conf           # Tmux configuration (purple theme)
│   └── tmux-plugins.md      # Plugin installation guide
├── linux/
│   └── openSuse_plasma6/    # KDE Plasma configs (rofi, kwin)
├── ruff.toml                # Python linting configuration
├── pyrightconfig.json       # Python type checking configuration
├── cheat-*.txt              # Keybinding cheat sheets
├── setup-system.sh          # Automated setup script
└── README.md
```

## Compatibility

Tested on:
- Ubuntu/Debian (apt)
- RHEL/CentOS/Fedora (yum/dnf)
- Arch Linux (pacman)
- openSUSE (zypper)
- macOS (Homebrew)

The setup script automatically detects your package manager.

## Environment Variables

The setup adds these to your shell config:
- `REPOS_PATH` - Your repositories directory
- `RUFF_CONFIG` - Path to ruff.toml
- `VENV_PATH` - Optional global Python venv

## Notes

- All configurations are non-destructive (backups created automatically)
- Font installation may require terminal restart
- Nvim plugins auto-install on first launch via lazy.nvim
- SSH key setup includes GitHub instructions
