#!/bin/bash

# Randy's System Configuration Setup Script
# This script sets up a new Linux system with all the development configurations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${PURPLE}===============================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}===============================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

prompt_user() {
    echo -e "${CYAN}$1${NC}"
    read -p "Press Enter to continue..."
}

# Detect package manager and distro
detect_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt install -y"
        PKG_UPDATE="apt update"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum update"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf update"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
    else
        print_error "No supported package manager found (apt, yum, dnf, pacman, zypper)"
        exit 1
    fi
    print_success "Detected package manager: $PKG_MANAGER"
}

# Get repos path from user
get_repos_path() {
    print_header "CONFIGURE REPOSITORIES PATH"
    echo -e "Where would you like to store your repositories?"
    echo -e "This will be used as the REPOS_PATH variable."
    echo -e "Default: ${GREEN}/home/$USER/repos${NC}"
    echo
    read -p "Enter path (or press Enter for default): " user_repos_path
    
    if [ -z "$user_repos_path" ]; then
        REPOS_PATH="/home/$USER/repos"
    else
        REPOS_PATH="$user_repos_path"
    fi
    
    # Ensure the path exists
    mkdir -p "$REPOS_PATH"
    print_success "Repositories path set to: $REPOS_PATH"
}

# Install system packages
install_system_packages() {
    print_header "INSTALLING SYSTEM PACKAGES"
    
    print_info "Updating package repositories..."
    sudo $PKG_UPDATE
    
    # Base packages needed for the setup
    base_packages=""
    modern_tools=""
    
    case $PKG_MANAGER in
        "apt")
            base_packages="git curl wget tmux neovim python3 python3-pip build-essential cmake unzip"
            modern_tools="bat fd-find ripgrep htop tree fzf ranger"
            ;;
        "yum"|"dnf")
            base_packages="git curl wget tmux neovim python3 python3-pip gcc gcc-c++ make cmake unzip"
            modern_tools="bat fd-find ripgrep htop tree fzf ranger"
            ;;
        "pacman")
            base_packages="git curl wget tmux neovim python python-pip base-devel cmake unzip"
            modern_tools="bat fd ripgrep htop tree fzf ranger"
            ;;
        "zypper")
            base_packages="git curl wget tmux neovim python3 python3-pip gcc gcc-c++ make cmake unzip"
            modern_tools="bat fd ripgrep htop tree fzf ranger"
            ;;
    esac
    
    print_info "Installing base packages..."
    sudo $PKG_INSTALL $base_packages
    
    print_info "Installing modern CLI tools..."
    sudo $PKG_INSTALL $modern_tools || print_warning "Some modern tools may not be available in your repos"
    
    print_success "System packages installed"
}

# Setup SSH key
setup_ssh_key() {
    print_header "SSH KEY CONFIGURATION"
    
    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        print_success "SSH key already exists"
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
        elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
        fi
    else
        print_info "Creating new SSH key..."
        read -p "Enter your email for SSH key: " email
        ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_ed25519" -N ""
        SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
        print_success "SSH key created"
    fi
    
    # Start SSH agent and add key
    eval "$(ssh-agent -s)" &> /dev/null
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
    
    echo -e "\n${YELLOW}IMPORTANT: Add this public key to your GitHub account:${NC}"
    echo -e "${CYAN}========================================${NC}"
    cat "$SSH_KEY_PATH"
    echo -e "${CYAN}========================================${NC}"
    echo
    echo -e "Steps to add to GitHub:"
    echo -e "1. Go to ${BLUE}https://github.com/settings/keys${NC}"
    echo -e "2. Click ${GREEN}'New SSH key'${NC}"
    echo -e "3. Copy the key above and paste it"
    echo -e "4. Give it a title like 'My Dev Machine'"
    echo -e "5. Click ${GREEN}'Add SSH key'${NC}"
    echo
    prompt_user "Please add the SSH key to GitHub and then press Enter to continue"
}

# Clone system configs
clone_system_configs() {
    print_header "CLONING SYSTEM CONFIGURATIONS"
    
    cd "$REPOS_PATH"
    
    if [ -d "system-configs" ]; then
        print_warning "system-configs directory already exists, pulling latest changes..."
        cd system-configs
        git pull
        cd ..
    else
        print_info "Cloning system-configs repository..."
        git clone git@github.com:randalmurphal/system-configs.git
        print_success "System configurations cloned"
    fi
}

# Backup existing configs
backup_configs() {
    print_header "BACKING UP EXISTING CONFIGURATIONS"
    
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing files
    [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$backup_dir/bashrc.bak"
    [ -f "$HOME/.tmux.conf" ] && cp "$HOME/.tmux.conf" "$backup_dir/tmux.conf.bak"
    [ -d "$HOME/.config/nvim" ] && cp -r "$HOME/.config/nvim" "$backup_dir/nvim.bak"
    
    print_success "Configurations backed up to: $backup_dir"
}

# Setup bashrc
setup_bashrc() {
    print_header "CONFIGURING BASHRC"
    
    # Create a temp file with our additions
    temp_additions=$(mktemp)
    
    # Replace REPOS_PATH in the template
    sed "s|/home/randy/repos|$REPOS_PATH|g" "$REPOS_PATH/system-configs/bash_configs/.bashrc" > "$temp_additions"
    
    # Check if our configurations are already present
    if grep -q "Randy's Terminal Setup Reference" "$HOME/.bashrc" 2>/dev/null; then
        print_warning "Randy's configurations already present in bashrc"
        echo "Do you want to update them? (y/n)"
        read -r update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            # Remove old Randy's configurations and add new ones
            grep -v "Randy's Terminal Setup Reference" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" || true
            cat "$temp_additions" >> "$HOME/.bashrc.tmp"
            mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
            print_success "Bashrc configurations updated"
        fi
    else
        # Append our configurations to existing bashrc
        echo -e "\n# Randy's Development Environment Configuration" >> "$HOME/.bashrc"
        cat "$temp_additions" >> "$HOME/.bashrc"
        print_success "Bashrc configurations added"
    fi
    
    rm "$temp_additions"
}

# Setup tmux
setup_tmux() {
    print_header "CONFIGURING TMUX"
    
    # Copy tmux configuration
    cp "$REPOS_PATH/system-configs/tmux_configs/.tmux.conf" "$HOME/.tmux.conf"
    print_success "Tmux configuration installed"
    
    # Install Tmux Plugin Manager
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        print_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        print_success "TPM installed"
    else
        print_success "TPM already installed"
    fi
    
    print_info "Installing tmux plugins..."
    echo -e "\n${YELLOW}After this script completes:${NC}"
    echo -e "1. Start tmux: ${GREEN}tmux${NC}"
    echo -e "2. Press ${GREEN}Ctrl+Space + I${NC} to install plugins"
    echo -e "3. Wait for installation to complete"
}

# Setup neovim
setup_neovim() {
    print_header "CONFIGURING NEOVIM"
    
    # Ensure nvim config directory exists
    mkdir -p "$HOME/.config/nvim"
    
    # Check if user wants to use Randy's nvim config or keep existing
    if [ -f "$HOME/.config/nvim/init.lua" ]; then
        print_warning "Existing Neovim configuration found"
        echo "Do you want to:"
        echo "1. Keep existing configuration (recommended)"
        echo "2. Replace with Randy's configuration"
        read -p "Choice (1 or 2): " nvim_choice
        
        if [ "$nvim_choice" = "2" ]; then
            print_info "You'll need to manually copy Randy's nvim configuration"
            echo -e "Randy's nvim config is typically in a separate repository."
            echo -e "Contact Randy for access to the nvim configuration repository."
        else
            print_success "Keeping existing Neovim configuration"
        fi
    else
        print_info "No existing Neovim configuration found"
        echo -e "You'll need Randy's nvim configuration repository for the full setup."
        echo -e "Contact Randy for access to the nvim configuration repository."
    fi
    
    # Install Python packages needed for development
    print_info "Installing Python development packages..."
    pip3 install --user ruff black isort pyright || print_warning "Some Python packages may have failed to install"
}

# Setup Git configuration
setup_git() {
    print_header "CONFIGURING GIT"
    
    # Check if git is already configured
    if ! git config --global user.name &> /dev/null; then
        echo "Git is not configured. Let's set it up:"
        read -p "Enter your full name: " git_name
        read -p "Enter your email: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        print_success "Git configured"
    else
        print_success "Git already configured"
        git_name=$(git config --global user.name)
        git_email=$(git config --global user.email)
        print_info "Using: $git_name <$git_email>"
    fi
}

# Install Hack Nerd Font
install_nerd_font() {
    print_header "INSTALLING HACK NERD FONT"
    
    font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    
    if [ ! -f "$font_dir/Hack Regular Nerd Font Complete.ttf" ]; then
        print_info "Downloading Hack Nerd Font..."
        cd /tmp
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip"
        unzip -q Hack.zip -d hack-font
        cp hack-font/*.ttf "$font_dir/"
        fc-cache -f -v &> /dev/null
        rm -rf hack-font Hack.zip
        print_success "Hack Nerd Font installed"
        print_info "You may need to change your terminal font to 'Hack Nerd Font'"
    else
        print_success "Hack Nerd Font already installed"
    fi
}

# Final instructions
show_final_instructions() {
    print_header "SETUP COMPLETE!"
    
    echo -e "${GREEN}🎉 Your development environment is now configured!${NC}\n"
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "1. ${CYAN}Reload your shell:${NC} source ~/.bashrc"
    echo -e "2. ${CYAN}Start tmux:${NC} tmux"
    echo -e "3. ${CYAN}Install tmux plugins:${NC} Ctrl+Space + I (in tmux)"
    echo -e "4. ${CYAN}Test your setup:${NC}"
    echo -e "   - keys               (show keybinding reference)"
    echo -e "   - keys --type nvim   (show only nvim bindings)"
    echo -e "   - cdsc               (go to system-configs)"
    echo -e "   - cdnv               (go to nvim config)"
    echo
    echo -e "${YELLOW}Python Development:${NC}"
    echo -e "- Your ruff.toml and pyrightconfig.json are configured"
    echo -e "- RUFF_CONFIG environment variable is set"
    echo -e "- Test with: ruff check <python-file>"
    echo
    echo -e "${YELLOW}Terminal Improvements:${NC}"
    echo -e "- Modern tools installed: bat, fd, ripgrep, htop, tree"
    echo -e "- Use 'bat' instead of 'cat' for syntax highlighting"
    echo -e "- Use 'fd' instead of 'find' for faster searches"
    echo -e "- Use 'rg' instead of 'grep' for faster text search"
    echo
    echo -e "${PURPLE}Enjoy your new development environment! 🚀${NC}"
}

# Main execution
main() {
    print_header "RANDY'S SYSTEM CONFIGURATION SETUP"
    echo -e "This script will set up your development environment with:"
    echo -e "• Modern terminal tools and aliases"
    echo -e "• Tmux configuration with plugins"
    echo -e "• Python development tools (ruff, black, pyright)"
    echo -e "• SSH key configuration"
    echo -e "• Git configuration"
    echo -e "• Nerd Font installation"
    echo
    echo -e "${YELLOW}This script will NOT remove existing configurations.${NC}"
    echo -e "${YELLOW}Backups will be created for safety.${NC}"
    echo
    read -p "Do you want to continue? (y/n): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    # Run setup steps
    detect_package_manager
    get_repos_path
    backup_configs
    install_system_packages
    setup_ssh_key
    clone_system_configs
    setup_git
    setup_bashrc
    setup_tmux
    setup_neovim
    install_nerd_font
    show_final_instructions
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please don't run this script as root. Run as your regular user."
    exit 1
fi

# Run main function
main "$@"