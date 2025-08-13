# Randy's System Configuration

This repository contains my personal development environment configurations for Linux systems.

## Quick Setup (New System)

For setting up a new Linux system with all configurations:

```bash
# Clone this repository
git clone https://github.com/randalmurphal/system-configs.git
cd system-configs

# Run the automated setup script
./setup-system.sh
```

The setup script will:
- Install modern CLI tools (bat, fd, ripgrep, htop, tree, fzf, ranger)
- Configure bash with aliases and environment variables
- Setup tmux with plugins and custom configuration
- Install Python development tools (ruff, black, pyright)
- Create SSH keys and provide GitHub setup instructions
- Install Hack Nerd Font for better terminal icons
- Configure git if not already set up
- Backup existing configurations before making changes

## Manual Setup

If you prefer to set things up manually:

### Bash Configuration
```bash
# Append configurations to your bashrc
cat bash_configs/.bashrc >> ~/.bashrc
source ~/.bashrc
```

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

### Python Development
```bash
# Copy Python configurations
cp ruff.toml ~/.config/ruff/pyproject.toml  # or set RUFF_CONFIG env var
cp pyrightconfig.json ~/your-project/

# Install Python tools
pip install ruff black isort pyright
```

## Key Features

### Command Line Tools
- **keys** - Show colorized keybinding reference
- **keys --type nvim** - Show only Neovim keybindings
- **keys --type tmux,bash** - Show multiple sections
- **cdsc** - Navigate to system-configs directory
- **cdnv** - Navigate to nvim configuration
- **setup-system** - Run full system setup

### Modern Tool Replacements
- `bat` instead of `cat` (syntax highlighting)
- `fd` instead of `find` (faster file search)
- `rg` instead of `grep` (faster text search)
- `htop` instead of `top` (better process viewer)

### Tmux Features
- **Prefix**: Ctrl+Space
- **Split panes**: prefix + s (horizontal), prefix + v (vertical)
- **Navigate panes**: Alt + hjkl
- **Copy mode**: prefix + k
- **File finder**: prefix + f (fzf integration)
- **System monitoring**: CPU, RAM, load in status bar

### Python Development
- Ruff linting with Pylance-compatible rules
- Pyright type checking with basic mode
- Black formatting with 79-character line length
- Single quote preference, no auto-fixing (highlight issues only)

## Repository Structure

```
system-configs/
├── bash_configs/
│   └── .bashrc              # Bash aliases, functions, and environment
├── tmux_configs/
│   ├── .tmux.conf          # Tmux configuration
│   └── tmux-plugins.md     # Plugin installation guide
├── ruff.toml               # Python linting configuration
├── pyrightconfig.json      # Python type checking configuration
├── show-keys               # Colorized keybinding reference script
├── setup-system.sh         # Automated setup script
├── keybindings-reference.md # Plain text keybinding reference
└── README.md               # This file
```

## Compatibility

Tested on:
- Ubuntu/Debian (apt)
- RHEL/CentOS/Fedora (yum/dnf)
- Arch Linux (pacman)
- openSUSE (zypper)

The setup script automatically detects your package manager and adjusts accordingly.

## Notes

- All configurations are designed to be non-destructive (won't remove existing settings)
- Backups are created automatically during setup
- SSH key setup includes instructions for GitHub integration
- Font installation may require terminal restart to take effect