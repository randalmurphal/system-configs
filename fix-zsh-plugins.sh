#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Fixing Zsh Plugin and Completion Issues for macOS${NC}\n"

# Detect if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is for macOS only${NC}"
    exit 1
fi

# Check if Oh My Zsh is installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${RED}Oh My Zsh is not installed${NC}"
    echo "Please run setup-system.sh first"
    exit 1
fi

echo -e "${YELLOW}Installing zsh plugins via Homebrew...${NC}"

# Install via Homebrew
brew install zsh-autosuggestions zsh-syntax-highlighting

echo -e "\n${YELLOW}Installing plugins to Oh My Zsh custom directory...${NC}"

# Also clone to oh-my-zsh custom plugins for compatibility
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo -e "${GREEN}✓ zsh-autosuggestions installed to Oh My Zsh${NC}"
else
    echo -e "${GREEN}✓ zsh-autosuggestions already in Oh My Zsh${NC}"
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    echo -e "${GREEN}✓ zsh-syntax-highlighting installed to Oh My Zsh${NC}"
else
    echo -e "${GREEN}✓ zsh-syntax-highlighting already in Oh My Zsh${NC}"
fi

echo -e "\n${YELLOW}Fixing Homebrew completions...${NC}"

# Fix broken brew_cask symlink
if [ -L "/usr/local/share/zsh/site-functions/_brew_cask" ]; then
    echo -e "${BLUE}Removing broken _brew_cask symlink...${NC}"
    rm -f /usr/local/share/zsh/site-functions/_brew_cask 2>/dev/null || \
        sudo rm -f /usr/local/share/zsh/site-functions/_brew_cask
    echo -e "${GREEN}✓ Removed broken symlink${NC}"
fi

# Fix brew completion if broken
if [ -L "/usr/local/share/zsh/site-functions/_brew" ] && [ ! -e "/usr/local/share/zsh/site-functions/_brew" ]; then
    echo -e "${BLUE}Fixing broken _brew symlink...${NC}"
    rm -f /usr/local/share/zsh/site-functions/_brew 2>/dev/null || \
        sudo rm -f /usr/local/share/zsh/site-functions/_brew
fi

# Ensure brew completions are properly linked
if command -v brew &> /dev/null; then
    BREW_PREFIX=$(brew --prefix)
    if [ -f "$BREW_PREFIX/share/zsh/site-functions/_brew" ]; then
        if [ ! -e "/usr/local/share/zsh/site-functions/_brew" ]; then
            sudo mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null || true
            sudo ln -sf "$BREW_PREFIX/share/zsh/site-functions/_brew" /usr/local/share/zsh/site-functions/_brew 2>/dev/null || true
            echo -e "${GREEN}✓ Fixed brew completions${NC}"
        fi
    fi
fi

echo -e "\n${YELLOW}Installing modern CLI tools...${NC}"

# Install modern replacements
brew install bat fd ripgrep eza fzf htop tree gdu ncdu tldr zoxide

echo -e "\n${YELLOW}Updating .zshrc for brew completions...${NC}"

# Add brew completions to .zshrc if not present
if ! grep -q "Fix Homebrew completions" ~/.zshrc 2>/dev/null; then
    cat >> ~/.zshrc << 'EOF'

# Fix Homebrew completions on macOS
if [[ "$OSTYPE" == "darwin"* ]] && type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    # Remove problematic completions
    rm -f /usr/local/share/zsh/site-functions/_brew_cask 2>/dev/null
fi
EOF
    echo -e "${GREEN}✓ Added brew completion fix to .zshrc${NC}"
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "\nNext steps:"
echo -e "1. Run: ${YELLOW}source ~/.zshrc${NC}"
echo -e "2. The plugins and completions should now work correctly"
echo -e "\nIf you still see errors:"
echo -e "- Try opening a new terminal window"
echo -e "- Remove ~/.zsh_profile if it exists (macOS uses ~/.zshrc for zsh)"
echo -e "- Run: ${YELLOW}rm -f ~/.zcompdump*${NC} to clear completion cache"
echo -e "- Run: ${YELLOW}exec zsh${NC} to restart your shell"