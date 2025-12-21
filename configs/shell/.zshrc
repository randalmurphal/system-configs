# Randy's ZSH Configuration - Portable across Linux/macOS
# This file sources modular configs from the same directory

# Get the directory where this script lives
ZSHRC_DIR="${0:A:h}"

# Source modular configs in order
source "$ZSHRC_DIR/core.zsh"        # oh-my-zsh, prompt, history, completions
source "$ZSHRC_DIR/aliases.zsh"     # Generic aliases
source "$ZSHRC_DIR/functions.zsh"   # Utility functions
source "$ZSHRC_DIR/path.zsh"        # PATH additions
source "$ZSHRC_DIR/toolchains.zsh"  # NVM, Go, etc.
