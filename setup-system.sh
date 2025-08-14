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
    echo -e "${GREEN}🎉 ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  🔔 $1${NC}"
}

print_error() {
    echo -e "${RED}💥 ❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}💡 ℹ️  $1${NC}"
}

prompt_user() {
    echo -e "${CYAN}$1${NC}"
    read -p "Press Enter to continue..."
}

# Detect package manager and distro
detect_package_manager() {
    if command -v brew &> /dev/null; then
        PKG_MANAGER="brew"
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update"
        OS_TYPE="macos"
    elif command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt install -y"
        PKG_UPDATE="apt update"
        OS_TYPE="linux"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum update"
        OS_TYPE="linux"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf update"
        OS_TYPE="linux"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
        OS_TYPE="linux"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_UPDATE="zypper refresh"
        OS_TYPE="linux"
    else
        print_error "No supported package manager found (brew, apt, yum, dnf, pacman, zypper)"
        print_error "On macOS, please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    print_success "Detected package manager: $PKG_MANAGER ($OS_TYPE)"
}

# Get repos path from user
get_repos_path() {
    print_header "CONFIGURE REPOSITORIES PATH"
    echo -e "Where would you like to store your repositories?"
    echo -e "This will be used as the REPOS_PATH variable."
    if [ "$OS_TYPE" = "macos" ]; then
        echo -e "Default: ${GREEN}/Users/$USER/repos${NC}"
    else
        echo -e "Default: ${GREEN}/home/$USER/repos${NC}"
    fi
    echo
    read -p "Enter path (or press Enter for default): " user_repos_path
    
    if [ -z "$user_repos_path" ]; then
        if [ "$OS_TYPE" = "macos" ]; then
            REPOS_PATH="/Users/$USER/repos"
        else
            REPOS_PATH="/home/$USER/repos"
        fi
    else
        REPOS_PATH="$user_repos_path"
    fi
    
    # Ensure the path exists
    mkdir -p "$REPOS_PATH"
    print_success "Repositories path set to: $REPOS_PATH"
}

# Get Python virtual environment path and create if needed
get_python_venv() {
    print_header "CONFIGURE PYTHON VIRTUAL ENVIRONMENT"
    echo -e "Where would you like to store your Python virtual environment?"
    echo -e "This will be automatically activated in your shell."
    echo -e "Default: ${GREEN}/opt/envs/py3${NC}"
    echo
    read -p "Enter path (or press Enter for default): " user_venv_path
    
    if [ -z "$user_venv_path" ]; then
        VENV_PATH="/opt/envs/py3"
    else
        VENV_PATH="$user_venv_path"
    fi
    
    # Check if virtual environment exists
    if [ -f "$VENV_PATH/bin/activate" ]; then
        print_success "Virtual environment already exists at: $VENV_PATH"
    else
        print_info "Virtual environment not found at: $VENV_PATH"
        echo "Do you want to create it? (y/n)"
        read -r create_venv
        
        if [ "$create_venv" = "y" ] || [ "$create_venv" = "Y" ]; then
            print_info "Creating virtual environment..."
            
            # Ensure parent directory exists
            sudo mkdir -p "$(dirname "$VENV_PATH")"
            
            # Create the virtual environment
            if python3 -m venv "$VENV_PATH"; then
                print_success "Virtual environment created at: $VENV_PATH"
                
                # Make it accessible to the user
                if [ "$OS_TYPE" != "macos" ]; then
                    sudo chown -R "$USER:$USER" "$VENV_PATH"
                fi
                
                # Activate and install some basic packages
                print_info "Installing basic Python packages..."
                source "$VENV_PATH/bin/activate"
                pip install --upgrade pip
                pip install ruff black isort pyright
                deactivate
                print_success "Basic Python packages installed"
            else
                print_error "Failed to create virtual environment"
                print_warning "You may need to install python3-venv package"
                VENV_PATH=""
            fi
        else
            print_warning "Skipping virtual environment creation"
            VENV_PATH=""
        fi
    fi
}

# Install system packages
install_system_packages() {
    print_header "INSTALLING SYSTEM PACKAGES"
    
    print_info "Updating package repositories..."
    if [ "$OS_TYPE" = "macos" ]; then
        $PKG_UPDATE
    else
        sudo $PKG_UPDATE
    fi
    
    # Base packages needed for the setup
    base_packages=""
    modern_tools=""
    
    case $PKG_MANAGER in
        "brew")
            base_packages="git curl wget tmux neovim python3 cmake unzip"
            modern_tools="bat fd ripgrep htop tree fzf ranger"
            ;;
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
    if [ "$OS_TYPE" = "macos" ]; then
        $PKG_INSTALL $base_packages
    else
        sudo $PKG_INSTALL $base_packages
    fi
    
    print_info "Installing modern CLI tools..."
    if [ "$OS_TYPE" = "macos" ]; then
        $PKG_INSTALL $modern_tools || print_warning "Some modern tools may not be available"
    else
        sudo $PKG_INSTALL $modern_tools || print_warning "Some modern tools may not be available in your repos"
    fi
    
    # Install pip3 on macOS if not present
    if [ "$OS_TYPE" = "macos" ] && ! command -v pip3 &> /dev/null; then
        print_info "Installing pip3..."
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py --user
        rm get-pip.py
    fi
    
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
        
        # Check if we're in a valid git repository
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            print_error "system-configs directory exists but is not a git repository"
            print_info "Please remove or rename the existing system-configs directory and run again"
            cd ..
            return 1
        fi
        
        # Check if we have a remote origin
        if ! git remote get-url origin > /dev/null 2>&1; then
            print_warning "No remote origin found, adding remote..."
            git remote add origin git@github.com:randalmurphal/system-configs.git
        fi
        
        # Fetch and pull with better error handling
        if git fetch origin > /dev/null 2>&1; then
            # Check if we have a main branch locally
            if git show-ref --verify --quiet refs/heads/main; then
                git pull origin main || print_warning "Failed to pull latest changes, continuing with existing version"
            else
                # Create and checkout main branch if it doesn't exist
                git checkout -b main origin/main || print_warning "Failed to create main branch, continuing"
            fi
        else
            print_warning "Failed to fetch from remote, continuing with existing version"
        fi
        cd ..
    else
        print_info "Cloning system-configs repository..."
        if git clone git@github.com:randalmurphal/system-configs.git; then
            print_success "System configurations cloned"
        else
            print_error "Failed to clone system-configs repository"
            print_info "Make sure your SSH key is added to GitHub and try again"
            return 1
        fi
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

# Setup shell configuration (bashrc on Linux, bash_profile on macOS)
setup_shell_config() {
    # Determine which shell config file to use based on OS
    if [ "$OS_TYPE" = "macos" ]; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
        CONFIG_NAME="bash_profile"
    else
        SHELL_CONFIG_FILE="$HOME/.bashrc"
        CONFIG_NAME="bashrc"
    fi
    
    print_header "CONFIGURING SHELL ($CONFIG_NAME)"
    
    # Create a temp file with our additions
    temp_additions=$(mktemp)
    
    # Replace REPOS_PATH and VENV_PATH in the template
    if [ -n "$VENV_PATH" ]; then
        sed -e "s|/home/randy/repos|$REPOS_PATH|g" -e "s|/Users/randy/repos|$REPOS_PATH|g" -e "s|VENV_PATH_PLACEHOLDER|$VENV_PATH|g" "$REPOS_PATH/system-configs/bash_configs/.bashrc" > "$temp_additions"
    else
        # If no venv path, comment out the venv section
        sed -e "s|/home/randy/repos|$REPOS_PATH|g" -e "s|/Users/randy/repos|$REPOS_PATH|g" -e "s|if \[ -f \"VENV_PATH_PLACEHOLDER|# if [ -f \"VENV_PATH_PLACEHOLDER|g" -e "s|source \"VENV_PATH_PLACEHOLDER|# source \"VENV_PATH_PLACEHOLDER|g" "$REPOS_PATH/system-configs/bash_configs/.bashrc" > "$temp_additions"
    fi
    
    # Check if our configurations are already present
    if grep -q "# Randy's Development Environment Configuration" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        print_warning "Randy's configurations already present in $CONFIG_NAME"
        echo "Do you want to update them? (y/n)"
        read -r update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            # Check for existing aliases and functions that might conflict
            check_existing_configurations "$SHELL_CONFIG_FILE"
            
            # Remove old Randy's configurations and add new ones
            # Create backup first
            cp "$SHELL_CONFIG_FILE" "$SHELL_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
            print_info "Backup created: $SHELL_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
            
            # Extract content before our marker
            sed '/# Randy'\''s Development Environment Configuration/,$d' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp"
            
            # Add our new configurations
            echo -e "\n# Randy's Development Environment Configuration" >> "$SHELL_CONFIG_FILE.tmp"
            cat "$temp_additions" >> "$SHELL_CONFIG_FILE.tmp"
            
            mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
            print_success "Shell configurations updated"
        else
            print_info "Keeping existing shell configurations"
        fi
    else
        # Check if shell config exists, if not create it
        if [ ! -f "$SHELL_CONFIG_FILE" ]; then
            print_info "Creating new $CONFIG_NAME file"
            touch "$SHELL_CONFIG_FILE"
        else
            # Check for existing aliases and functions that might conflict
            check_existing_configurations "$SHELL_CONFIG_FILE"
        fi
        
        # Append our configurations to existing shell config
        echo -e "\n# Randy's Development Environment Configuration" >> "$SHELL_CONFIG_FILE"
        cat "$temp_additions" >> "$SHELL_CONFIG_FILE"
        print_success "Shell configurations added to $CONFIG_NAME"
    fi
    
    rm "$temp_additions"
}

# Check for existing configurations that might conflict
check_existing_configurations() {
    local config_file="$1"
    local conflicts_found=false
    
    print_info "Checking for potential conflicts in existing configurations..."
    
    # Common aliases that we'll be overriding
    local our_aliases="ls grep find cat top du ping vim vi rm cp mv"
    local our_functions="extract mkcd killp serve parse_git_branch parse_git_dirty"
    
    # Check for existing aliases
    for alias_name in $our_aliases; do
        if grep -q "^[[:space:]]*alias[[:space:]]\+$alias_name=" "$config_file" 2>/dev/null; then
            if [ "$conflicts_found" = false ]; then
                echo -e "\n${YELLOW}Found existing configurations that will be overridden:${NC}"
                conflicts_found=true
            fi
            print_warning "Alias: $alias_name"
        fi
    done
    
    # Check for existing functions
    for func_name in $our_functions; do
        if grep -q "^[[:space:]]*$func_name[[:space:]]*(" "$config_file" 2>/dev/null; then
            if [ "$conflicts_found" = false ]; then
                echo -e "\n${YELLOW}Found existing configurations that will be overridden:${NC}"
                conflicts_found=true
            fi
            print_warning "Function: $func_name"
        fi
    done
    
    # Check for tmux auto-start
    if grep -q "tmux.*main" "$config_file" 2>/dev/null; then
        if [ "$conflicts_found" = false ]; then
            echo -e "\n${YELLOW}Found existing configurations that will be overridden:${NC}"
            conflicts_found=true
        fi
        print_warning "Tmux auto-start configuration"
    fi
    
    if [ "$conflicts_found" = true ]; then
        echo -e "\n${CYAN}These existing configurations will be preserved in the backup file.${NC}"
        echo "Do you want to continue and override these configurations? (y/n)"
        read -r override_choice
        if [ "$override_choice" != "y" ] && [ "$override_choice" != "Y" ]; then
            print_error "Configuration setup cancelled by user"
            exit 1
        fi
    fi
}

# Setup tmux
setup_tmux() {
    print_header "CONFIGURING TMUX"
    
    # Check if tmux config already exists
    if [ -f "$HOME/.tmux.conf" ]; then
        print_warning "Existing tmux configuration found"
        echo "Current tmux config will be backed up. Continue? (y/n)"
        read -r tmux_choice
        if [ "$tmux_choice" != "y" ] && [ "$tmux_choice" != "Y" ]; then
            print_info "Skipping tmux configuration"
            return
        fi
        
        # Create backup
        cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Backup created: $HOME/.tmux.conf.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
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
    if [ -f "$HOME/.config/nvim/init.lua" ] || [ -f "$HOME/.config/nvim/init.vim" ]; then
        print_warning "Existing Neovim configuration found"
        echo "Current nvim config will be backed up if replaced. What would you like to do?"
        echo "1. Keep existing configuration (recommended)"
        echo "2. Replace with Randy's configuration"
        read -p "Choice (1 or 2): " nvim_choice
        
        if [ "$nvim_choice" = "2" ]; then
            # Create backup
            backup_dir="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"
            cp -r "$HOME/.config/nvim" "$backup_dir"
            print_info "Backup created: $backup_dir"
            
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
    if [ -n "$VENV_PATH" ] && [ -f "$VENV_PATH/bin/activate" ]; then
        print_info "Installing Python development packages in virtual environment..."
        source "$VENV_PATH/bin/activate"
        pip install --upgrade pip
        pip install ruff black isort pyright || print_warning "Some Python packages may have failed to install"
        deactivate
    else
        print_info "Installing Python development packages globally..."
        pip3 install --user ruff black isort pyright || print_warning "Some Python packages may have failed to install"
    fi
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
    
    if [ "$OS_TYPE" = "macos" ]; then
        # Check if Hack Nerd Font is already installed via Homebrew
        if brew list --cask font-hack-nerd-font &> /dev/null; then
            print_success "Hack Nerd Font already installed"
        else
            print_info "Installing Hack Nerd Font via Homebrew..."
            # The fonts are now in the main homebrew/cask repository
            if brew install --cask font-hack-nerd-font; then
                print_success "Hack Nerd Font installed"
                print_info "You may need to change your terminal font to 'Hack Nerd Font'"
            else
                print_warning "Failed to install via Homebrew, trying manual installation..."
                # Fallback to manual installation
                font_dir="$HOME/Library/Fonts"
                mkdir -p "$font_dir"
                cd /tmp
                if curl -L -o Hack.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip"; then
                    unzip -q Hack.zip -d hack-font
                    cp hack-font/*.ttf "$font_dir/"
                    rm -rf hack-font Hack.zip
                    print_success "Hack Nerd Font installed manually"
                    print_info "You may need to change your terminal font to 'Hack Nerd Font'"
                else
                    print_warning "Failed to install Hack Nerd Font"
                fi
            fi
        fi
    else
        # Linux installation
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
    fi
}

# Final instructions
show_final_instructions() {
    echo -e "${GREEN}"
    cat << 'EOF'
    ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗
    ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║
    ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║
    ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝
    ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗
    ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝
                                                               
EOF
    echo -e "${NC}"
    print_header "🎯 MISSION ACCOMPLISHED! 🎯"
    
    echo -e "${GREEN}🚀 Your development environment has been supercharged! 🚀${NC}\n"
    
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
    echo -e "${PURPLE}"
    cat << 'EOF'
      ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
     ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌          
     ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
     ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
     ▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
     ▐░▌     ▐░▌  ▐░▌       ▐░▌▐░▌          ▐░▌          
     ▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ 
     ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
      ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀ 
                                                       
      Happy coding in your epic development environment! 🎮🔥💻
EOF
    echo -e "${NC}"
}

# Main execution
main() {
    # Detect OS and package manager first
    detect_package_manager
    
    echo -e "${PURPLE}"
    cat << 'EOF'
    ██████╗  █████╗ ███╗   ██╗██████╗ ██╗   ██╗███████╗
    ██╔══██╗██╔══██╗████╗  ██║██╔══██╗╚██╗ ██╔╝██╔════╝
    ██████╔╝███████║██╔██╗ ██║██║  ██║ ╚████╔╝ ███████╗
    ██╔══██╗██╔══██║██║╚██╗██║██║  ██║  ╚██╔╝  ╚════██║
    ██║  ██║██║  ██║██║ ╚████║██████╔╝   ██║   ███████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝    ╚═╝   ╚══════╝
    
    ███████╗██╗   ██╗██████╗ ███████╗██████╗   ██████╗ ███████╗██╗   ██╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗  ██╔══██╗██╔════╝██║   ██║
    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝  ██║  ██║█████╗  ██║   ██║
    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗  ██║  ██║██╔══╝  ╚██╗ ██╔╝
    ███████║╚██████╔╝██║     ███████╗██║  ██║  ██████╔╝███████╗ ╚████╔╝ 
    ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝  ╚═════╝ ╚══════╝  ╚═══╝  
                                                                        
EOF
    echo -e "${NC}"
    print_header "EPIC DEVELOPMENT ENVIRONMENT SETUP"
    echo -e "${CYAN}🚀 Preparing to transform your $OS_TYPE machine into a dev powerhouse! 🚀${NC}"
    echo -e "This script will set up your development environment on $OS_TYPE with:"
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
    get_repos_path
    get_python_venv
    backup_configs
    install_system_packages
    setup_ssh_key
    clone_system_configs
    setup_git
    setup_shell_config
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