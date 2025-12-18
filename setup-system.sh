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

# Choose shell (zsh or bash)
choose_shell() {
    print_header "SHELL SELECTION"
    echo -e "Which shell would you like to use as your default?"
    echo -e "1. ${GREEN}Zsh${NC} (recommended - modern shell with better features)"
    echo -e "2. ${YELLOW}Bash${NC} (traditional shell)"
    echo
    
    # Check if zsh is already installed
    if command -v zsh &> /dev/null; then
        print_success "Zsh is already installed"
        ZSH_AVAILABLE=true
    else
        print_warning "Zsh is not installed - will be installed if selected"
        ZSH_AVAILABLE=false
    fi
    
    echo -e "Default: ${GREEN}Zsh${NC}"
    read -p "Enter choice (1 for zsh, 2 for bash, or press Enter for default): " shell_choice
    
    case "$shell_choice" in
        "2"|"bash"|"Bash"|"BASH")
            CHOSEN_SHELL="bash"
            print_success "Selected: Bash"
            ;;
        "1"|"zsh"|"Zsh"|"ZSH"|"")
            CHOSEN_SHELL="zsh"
            print_success "Selected: Zsh"
            if [ "$ZSH_AVAILABLE" = false ]; then
                INSTALL_ZSH=true
                print_info "Zsh will be installed during package installation"
            fi
            ;;
        *)
            print_warning "Invalid choice, defaulting to Zsh"
            CHOSEN_SHELL="zsh"
            if [ "$ZSH_AVAILABLE" = false ]; then
                INSTALL_ZSH=true
                print_info "Zsh will be installed during package installation"
            fi
            ;;
    esac
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

# Get Python virtual environment path (existing only, no creation)
get_python_venv() {
    print_header "CONFIGURE PYTHON VIRTUAL ENVIRONMENT"
    echo -e "Do you have an existing Python virtual environment you want to auto-activate?"
    echo -e "This will add it to your shell startup."
    echo
    read -p "Use existing venv? (y/n): " use_venv

    if [ "$use_venv" != "y" ] && [ "$use_venv" != "Y" ]; then
        print_info "Skipping virtual environment setup"
        print_info "Note: If you need a Python venv later, create one and add it to ~/.zsh.d/00-venv.sh"
        VENV_PATH=""
        return 0
    fi

    echo -e "Enter the path to your existing virtual environment:"
    echo -e "Example: ${GREEN}/opt/envs/myenv${NC} or ${GREEN}$HOME/.venv${NC}"
    echo
    read -p "Venv path: " user_venv_path

    if [ -z "$user_venv_path" ]; then
        print_warning "No path provided, skipping venv setup"
        VENV_PATH=""
        return 0
    fi

    # Expand ~ if used
    user_venv_path="${user_venv_path/#\~/$HOME}"

    # Check if virtual environment exists
    if [ -f "$user_venv_path/bin/activate" ]; then
        VENV_PATH="$user_venv_path"
        print_success "Virtual environment found at: $VENV_PATH"
    else
        print_error "No valid venv found at: $user_venv_path"
        print_info "Expected to find: $user_venv_path/bin/activate"
        print_warning "Skipping venv setup. Create a venv first, then add to ~/.zsh.d/00-venv.sh"
        VENV_PATH=""
    fi
}

# Select optional components
select_components() {
    print_header "SELECT COMPONENTS TO INSTALL"
    echo -e "Choose which components you want to install."
    echo -e "Enter 'y' for yes, 'n' for no, or press Enter for default (yes).\n"

    # System packages
    read -p "Install system packages (git, tmux, neovim, modern CLI tools)? [Y/n]: " choice
    INSTALL_SYSTEM_PACKAGES=${choice:-y}
    INSTALL_SYSTEM_PACKAGES=$(echo "$INSTALL_SYSTEM_PACKAGES" | tr '[:upper:]' '[:lower:]')

    # SSH key
    read -p "Setup SSH key? [Y/n]: " choice
    SETUP_SSH=${choice:-y}
    SETUP_SSH=$(echo "$SETUP_SSH" | tr '[:upper:]' '[:lower:]')

    # Git config
    read -p "Configure Git? [Y/n]: " choice
    SETUP_GIT=${choice:-y}
    SETUP_GIT=$(echo "$SETUP_GIT" | tr '[:upper:]' '[:lower:]')

    # Shell configuration (bash/zsh)
    read -p "Setup shell configuration ($CHOSEN_SHELL)? [Y/n]: " choice
    SETUP_SHELL=${choice:-y}
    SETUP_SHELL=$(echo "$SETUP_SHELL" | tr '[:upper:]' '[:lower:]')

    # Tmux
    read -p "Setup tmux configuration? [Y/n]: " choice
    SETUP_TMUX=${choice:-y}
    SETUP_TMUX=$(echo "$SETUP_TMUX" | tr '[:upper:]' '[:lower:]')

    # Neovim
    read -p "Setup Neovim configuration? [Y/n]: " choice
    SETUP_NEOVIM=${choice:-y}
    SETUP_NEOVIM=$(echo "$SETUP_NEOVIM" | tr '[:upper:]' '[:lower:]')

    # Nerd Font
    read -p "Install Hack Nerd Font? [Y/n]: " choice
    INSTALL_FONT=${choice:-y}
    INSTALL_FONT=$(echo "$INSTALL_FONT" | tr '[:upper:]' '[:lower:]')

    echo
    print_success "Component selection complete"
}

# Fix Homebrew completions for macOS
fix_brew_completions() {
    if [ "$OS_TYPE" != "macos" ]; then
        return 0
    fi
    
    print_info "Fixing Homebrew completions..."
    
    # Remove broken symlinks
    if [ -L "/usr/local/share/zsh/site-functions/_brew_cask" ]; then
        print_info "Removing broken _brew_cask symlink..."
        rm -f /usr/local/share/zsh/site-functions/_brew_cask 2>/dev/null || 
            sudo rm -f /usr/local/share/zsh/site-functions/_brew_cask 2>/dev/null || 
            print_warning "Could not remove broken symlink"
    fi
    
    # Fix brew completion symlink if broken
    if [ -L "/usr/local/share/zsh/site-functions/_brew" ] && [ ! -e "/usr/local/share/zsh/site-functions/_brew" ]; then
        print_info "Fixing broken _brew symlink..."
        rm -f /usr/local/share/zsh/site-functions/_brew 2>/dev/null || 
            sudo rm -f /usr/local/share/zsh/site-functions/_brew 2>/dev/null
    fi
    
    # Ensure brew completions are properly linked
    if command -v brew &> /dev/null; then
        BREW_PREFIX=$(brew --prefix)
        if [ -f "$BREW_PREFIX/share/zsh/site-functions/_brew" ]; then
            print_info "Brew completions found at $BREW_PREFIX"
            # Create directory if it doesn't exist
            if [ ! -d "/usr/local/share/zsh/site-functions" ]; then
                sudo mkdir -p /usr/local/share/zsh/site-functions 2>/dev/null || true
            fi
            # Link if not already linked
            if [ ! -e "/usr/local/share/zsh/site-functions/_brew" ]; then
                ln -sf "$BREW_PREFIX/share/zsh/site-functions/_brew" /usr/local/share/zsh/site-functions/_brew 2>/dev/null || 
                    sudo ln -sf "$BREW_PREFIX/share/zsh/site-functions/_brew" /usr/local/share/zsh/site-functions/_brew 2>/dev/null || true
            fi
        fi
    fi
    
    # Add to fpath in zshrc if needed
    if [ -f "$HOME/.zshrc" ] && ! grep -q "fpath.*site-functions" "$HOME/.zshrc"; then
        print_info "Adding Homebrew completions to fpath in .zshrc..."
        # Add before compinit
        sed -i.bak '/^source \$ZSH\/oh-my-zsh.sh/i\
# Fix Homebrew completions\
if type brew &>/dev/null; then\
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"\
    autoload -Uz compinit\
    compinit\
fi\
' "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    print_success "Homebrew completions fixed"
}

# Check neovim version - returns 0 if version >= minimum, 1 otherwise
check_nvim_version() {
    local min_version="${1:-0.9.0}"

    if ! command -v nvim &> /dev/null; then
        return 1
    fi

    local current_version=$(nvim --version 2>/dev/null | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")

    # Compare versions (simple numeric comparison)
    local current_major=$(echo "$current_version" | cut -d. -f1)
    local current_minor=$(echo "$current_version" | cut -d. -f2)
    local min_major=$(echo "$min_version" | cut -d. -f1)
    local min_minor=$(echo "$min_version" | cut -d. -f2)

    if [ "$current_major" -gt "$min_major" ]; then
        return 0
    elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -ge "$min_minor" ]; then
        return 0
    else
        return 1
    fi
}

# Install neovim on Linux with version checking and fallbacks
install_neovim_linux() {
    local MIN_NVIM_VERSION="0.9.0"

    print_info "Checking neovim installation..."

    # Check if nvim is already installed with sufficient version
    if check_nvim_version "$MIN_NVIM_VERSION"; then
        local current_version=$(nvim --version | head -1)
        print_success "Neovim already installed: $current_version"
        return 0
    fi

    # For apt-based systems, avoid the outdated apt version
    if [ "$PKG_MANAGER" = "apt" ]; then
        print_info "apt has outdated neovim - trying alternatives..."

        # Try snap first (preferred)
        if command -v snap &> /dev/null; then
            print_info "Installing neovim via snap..."
            if sudo snap install nvim --classic; then
                print_success "Neovim installed via snap"
                return 0
            fi
            print_warning "snap install failed, trying AppImage..."
        fi

        # Fallback to AppImage
        print_info "Installing neovim via AppImage..."
        local nvim_appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
        local nvim_install_dir="$HOME/.local/bin"
        mkdir -p "$nvim_install_dir"

        if curl -Lo "$nvim_install_dir/nvim" "$nvim_appimage_url" && chmod +x "$nvim_install_dir/nvim"; then
            # Test if AppImage works (some systems need FUSE)
            if "$nvim_install_dir/nvim" --version &> /dev/null; then
                print_success "Neovim AppImage installed to $nvim_install_dir/nvim"
                print_info "Make sure $nvim_install_dir is in your PATH"
                return 0
            else
                print_warning "AppImage requires FUSE. Extracting instead..."
                cd "$nvim_install_dir"
                ./nvim --appimage-extract &> /dev/null
                rm nvim
                ln -sf squashfs-root/usr/bin/nvim nvim
                if ./nvim --version &> /dev/null; then
                    print_success "Neovim extracted and installed to $nvim_install_dir/nvim"
                    return 0
                fi
                print_error "Failed to install neovim AppImage"
                cd - > /dev/null
            fi
        fi

        print_error "Could not install neovim automatically"
        print_info "Manual options:"
        print_info "  1. Install snapd: sudo apt install snapd && sudo snap install nvim --classic"
        print_info "  2. Build from source: https://github.com/neovim/neovim/wiki/Building-Neovim"
        return 1
    fi

    # For other package managers, install via package manager and check version
    print_info "Installing neovim via $PKG_MANAGER..."
    sudo $PKG_INSTALL neovim || {
        print_warning "Failed to install neovim via $PKG_MANAGER"
        return 1
    }

    # Check if installed version meets requirements
    if check_nvim_version "$MIN_NVIM_VERSION"; then
        local current_version=$(nvim --version | head -1)
        print_success "Neovim installed: $current_version"
    else
        local current_version=$(nvim --version 2>/dev/null | head -1 || echo "unknown")
        print_warning "Installed neovim version ($current_version) may be too old"
        print_warning "Minimum recommended: v$MIN_NVIM_VERSION"
        print_info "For latest version, consider installing from:"
        print_info "  - AppImage: https://github.com/neovim/neovim/releases"
        print_info "  - Build from source: https://github.com/neovim/neovim/wiki/Building-Neovim"
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
            modern_tools="bat ripgrep htop tree fzf ranger zoxide gdu ncdu tldr lazygit btop"
            if [ "$INSTALL_ZSH" = true ]; then
                base_packages="$base_packages zsh"
            fi
            ;;
        "apt")
            base_packages="git curl wget tmux python3 python3-pip build-essential cmake unzip"
            modern_tools="bat ripgrep htop tree fzf ranger ncdu tldr"
            # Note: zoxide, lazygit, btop may need manual installation on some distros
            if [ "$INSTALL_ZSH" = true ]; then
                base_packages="$base_packages zsh"
            fi
            ;;
        "yum"|"dnf")
            base_packages="git curl wget tmux neovim python3 python3-pip gcc gcc-c++ make cmake unzip"
            modern_tools="bat ripgrep htop tree fzf ranger tldr"
            if [ "$INSTALL_ZSH" = true ]; then
                base_packages="$base_packages zsh"
            fi
            ;;
        "pacman")
            base_packages="git curl wget tmux neovim python python-pip base-devel cmake unzip"
            modern_tools="bat ripgrep htop tree fzf ranger lazygit btop"
            if [ "$INSTALL_ZSH" = true ]; then
                base_packages="$base_packages zsh"
            fi
            ;;
        "zypper")
            base_packages="git curl wget tmux neovim python3 python3-pip gcc gcc-c++ make cmake unzip"
            modern_tools="bat ripgrep htop tree fzf ranger lazygit btop tldr"
            if [ "$INSTALL_ZSH" = true ]; then
                base_packages="$base_packages zsh"
            fi
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
        
        # Try to install zoxide on Linux if not in default repos
        if ! command -v zoxide &> /dev/null; then
            print_info "Attempting to install zoxide..."
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash 2>/dev/null || print_warning "Failed to install zoxide"
        fi

        # Install neovim - handle version requirements
        install_neovim_linux
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

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ "$CHOSEN_SHELL" != "zsh" ]; then
        return 0  # Skip if not using zsh
    fi
    
    print_header "INSTALLING OH MY ZSH"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
        # Don't return - still need to install plugins
    else
    
    print_info "Installing Oh My Zsh..."
    
    # Download and install Oh My Zsh non-interactively
    if command -v curl &> /dev/null; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
            print_error "Failed to install Oh My Zsh via curl"
            return 1
        }
    elif command -v wget &> /dev/null; then
        RUNZSH=no CHSH=no sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
            print_error "Failed to install Oh My Zsh via wget"
            return 1
        }
    else
        print_error "Neither curl nor wget found - cannot install Oh My Zsh"
        return 1
    fi
    
        print_success "Oh My Zsh installed successfully"
    fi
    
    # Install popular plugins - ALWAYS run this section
    print_info "Installing Oh My Zsh plugins..."
    
    # For macOS, we'll install via both methods for maximum compatibility
    if [ "$OS_TYPE" = "macos" ]; then
        # Install via Homebrew first (system-wide)
        print_info "Installing zsh plugins via Homebrew..."
        brew install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || print_warning "Some plugins may already be installed"
    fi
    
    # Install zsh-autosuggestions to Oh My Zsh custom directory
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        print_info "Installing zsh-autosuggestions to Oh My Zsh..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || 
            print_warning "Failed to install zsh-autosuggestions to Oh My Zsh"
    else
        print_success "zsh-autosuggestions already in Oh My Zsh"
    fi
    
    # Install zsh-syntax-highlighting to Oh My Zsh custom directory
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        print_info "Installing zsh-syntax-highlighting to Oh My Zsh..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || 
            print_warning "Failed to install zsh-syntax-highlighting to Oh My Zsh"
    else
        print_success "zsh-syntax-highlighting already in Oh My Zsh"
    fi
    
    print_success "Oh My Zsh plugins installed"
}

# Setup shell configuration (supports both bash and zsh)
setup_shell_config() {
    if [ "$CHOSEN_SHELL" = "zsh" ]; then
        setup_zsh_config
    else
        setup_bash_config
    fi
}

# Setup ZSH configuration (modular approach)
setup_zsh_config() {
    print_header "CONFIGURING ZSH (Modular Setup)"

    SHELL_CONFIG_FILE="$HOME/.zshrc"
    ZSH_LOCAL_DIR="$HOME/.zsh.d"

    # Check for .zsh_profile (non-standard file)
    if [ -f "$HOME/.zsh_profile" ]; then
        print_warning "Found .zsh_profile (non-standard file - Zsh uses .zshrc)"
        echo "Would you like to back it up and remove it? (y/n)"
        read -p "Choice: " profile_choice
        if [ "$profile_choice" = "y" ] || [ "$profile_choice" = "Y" ]; then
            mv "$HOME/.zsh_profile" "$HOME/.zsh_profile.backup-$(date +%Y%m%d-%H%M%S)"
            print_info "Backed up .zsh_profile"
        fi
    fi

    # Create ~/.zsh.d/ directory
    print_info "Creating local config directory: $ZSH_LOCAL_DIR"
    mkdir -p "$ZSH_LOCAL_DIR"

    # Create README in ~/.zsh.d/
    create_zsh_local_readme

    # Create venv config if user specified one
    if [ -n "$VENV_PATH" ]; then
        print_info "Creating venv activation config..."
        cat > "$ZSH_LOCAL_DIR/00-venv.sh" << EOF
# Virtual Environment Activation
# Auto-activate this venv on shell startup

source "$VENV_PATH/bin/activate"
EOF
        print_success "Created $ZSH_LOCAL_DIR/00-venv.sh"
    fi

    # Create REPOS_PATH override if not default
    if [ "$REPOS_PATH" != "$HOME/repos" ]; then
        print_info "Creating custom REPOS_PATH config..."
        cat > "$ZSH_LOCAL_DIR/05-paths.sh" << EOF
# Custom Paths
# Set before system-configs is sourced to override defaults

export REPOS_PATH="$REPOS_PATH"
EOF
        print_success "Created $ZSH_LOCAL_DIR/05-paths.sh"
    fi

    # Check if ~/.zshrc already sources system-configs (idempotent check)
    if [ -f "$SHELL_CONFIG_FILE" ] && grep -q "system-configs/zsh_configs" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        print_success "~/.zshrc already configured to source system-configs"
        echo "Do you want to regenerate it anyway? (y/n)"
        read -r regen_choice
        if [ "$regen_choice" != "y" ] && [ "$regen_choice" != "Y" ]; then
            print_info "Keeping existing ~/.zshrc"
            return 0
        fi
        # Backup existing
        cp "$SHELL_CONFIG_FILE" "$SHELL_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Backed up existing ~/.zshrc"
    elif [ -f "$SHELL_CONFIG_FILE" ]; then
        # Backup existing zshrc that doesn't have our config
        cp "$SHELL_CONFIG_FILE" "$SHELL_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Backed up existing ~/.zshrc"
    fi

    # Create new ~/.zshrc
    print_info "Creating ~/.zshrc..."
    cat > "$SHELL_CONFIG_FILE" << 'ZSHRC_EOF'
# Randy's ZSH Configuration
# Minimal loader - sources portable config + local machine-specific configs

# ========================================
# LOCAL CONFIG (machine-specific, loaded first for overrides)
# ========================================
# Source all files in ~/.zsh.d/ in alphabetical order
# (N) = nullglob - don't error if no matches
for conf in ~/.zsh.d/*.sh(N); do
    source "$conf"
done

# ========================================
# PORTABLE CONFIG (from system-configs repo)
# ========================================
ZSHRC_EOF

    # Add the source line with the actual REPOS_PATH
    echo "source \"$REPOS_PATH/system-configs/zsh_configs/.zshrc\"" >> "$SHELL_CONFIG_FILE"

    cat >> "$SHELL_CONFIG_FILE" << 'ZSHRC_EOF'

# ========================================
# MACHINE-SPECIFIC OVERRIDES
# ========================================
# Add any machine-specific settings below this line
# (or better: put them in ~/.zsh.d/90-local.sh)

# Increase file descriptor limit for various tools
ulimit -n 4096 2>/dev/null

# macOS-specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
fi
ZSHRC_EOF

    print_success "Created ~/.zshrc"
    print_info "Local configs go in: $ZSH_LOCAL_DIR/"
    print_info "See $ZSH_LOCAL_DIR/README for details"
}

# Create README for ~/.zsh.d/
create_zsh_local_readme() {
    cat > "$ZSH_LOCAL_DIR/README" << 'README_EOF'
# ~/.zsh.d/ - Local ZSH Configuration

This directory contains machine-specific shell configuration that is NOT
committed to version control. Files are sourced in alphabetical order.

## File Naming Convention

Use numbered prefixes to control load order:
- 00-*.sh  - Early setup (venv activation, PATH prepends)
- 05-*.sh  - Path overrides (REPOS_PATH, etc.)
- 10-*.sh  - Project-specific config (aliases, env vars)
- 20-*.sh  - Tool-specific config (Claude, MCP, etc.)
- 30-*.sh  - Credentials (chmod 600!)
- 90-*.sh  - Local overrides (machine-specific tweaks)

## Example Files

00-venv.sh:
    source /path/to/your/venv/bin/activate

10-myproject.sh:
    export PROJECT_API_KEY="..."
    alias cdp="cd ~/repos/myproject"

30-credentials.sh:  (chmod 600!)
    export GITHUB_TOKEN="..."
    export AWS_ACCESS_KEY_ID="..."

## Important

- Files must end in .sh to be sourced
- Credentials files should be chmod 600
- These files are NOT tracked in git
- The system-configs repo has the portable/shared config
README_EOF
    print_success "Created $ZSH_LOCAL_DIR/README"
}

# Setup Bash configuration (legacy monolithic approach)
setup_bash_config() {
    print_header "CONFIGURING BASH"

    # Bash configuration - determine based on OS
    if [ "$OS_TYPE" = "macos" ]; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
        CONFIG_NAME="bash_profile"
    else
        SHELL_CONFIG_FILE="$HOME/.bashrc"
        CONFIG_NAME="bashrc"
    fi
    CONFIG_TEMPLATE="$REPOS_PATH/system-configs/bash_configs/.bashrc"

    # Create a temp file with our additions
    temp_additions=$(mktemp)

    # Replace REPOS_PATH and VENV_PATH in the template
    if [ -n "$VENV_PATH" ]; then
        sed -e "s|REPOS_PATH_PLACEHOLDER|$REPOS_PATH|g" -e "s|VENV_PATH_PLACEHOLDER|$VENV_PATH|g" "$CONFIG_TEMPLATE" > "$temp_additions"
    else
        sed -e "s|REPOS_PATH_PLACEHOLDER|$REPOS_PATH|g" -e "s|if \[ -f \"VENV_PATH_PLACEHOLDER|# if [ -f \"VENV_PATH_PLACEHOLDER|g" -e "s|source \"VENV_PATH_PLACEHOLDER|# source \"VENV_PATH_PLACEHOLDER|g" "$CONFIG_TEMPLATE" > "$temp_additions"
    fi

    # Define start and end markers
    START_MARKER="# === START: Randy's Development Environment Configuration ==="
    END_MARKER="# === END: Randy's Development Environment Configuration ==="

    if [ ! -f "$SHELL_CONFIG_FILE" ]; then
        print_info "Creating new $CONFIG_NAME file"
        touch "$SHELL_CONFIG_FILE"
    fi

    # Check if our configuration section already exists
    if grep -q "$START_MARKER" "$SHELL_CONFIG_FILE" 2>/dev/null; then
        print_warning "Randy's configuration section found in $CONFIG_NAME"
        echo "Do you want to replace it with the latest? (y/n)"
        read -r update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            cp "$SHELL_CONFIG_FILE" "$SHELL_CONFIG_FILE.backup-$(date +%Y%m%d-%H%M%S)"
            START_ESCAPED=$(printf '%s\n' "$START_MARKER" | sed 's/[[\.*^$()+?{|]/\\&/g')
            END_ESCAPED=$(printf '%s\n' "$END_MARKER" | sed 's/[[\.*^$()+?{|]/\\&/g')
            sed "/$START_ESCAPED/,/$END_ESCAPED/d" "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp"
            mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"
        else
            print_info "Keeping existing configuration"
            rm "$temp_additions"
            return
        fi
    fi

    echo -e "\n$START_MARKER" >> "$SHELL_CONFIG_FILE"
    cat "$temp_additions" >> "$SHELL_CONFIG_FILE"
    echo -e "$END_MARKER" >> "$SHELL_CONFIG_FILE"

    print_success "Bash configuration updated"
    rm "$temp_additions"
}

# Check for existing configurations that might conflict
check_existing_configurations() {
    local config_file="$1"
    local conflicts_found=false
    
    print_info "Checking for potential conflicts in existing configurations..."
    
    # Common aliases that we'll be overriding (cross-shell)
    local our_aliases="ls grep find cat top du ping vim vi rm cp mv ll la lt tree bat fd"
    local our_functions="extract killp serve"
    
    # Add shell-specific functions
    if [ "$CHOSEN_SHELL" = "zsh" ]; then
        our_functions="$our_functions git_branch virtualenv_info"
    else
        our_functions="$our_functions parse_git_branch parse_git_dirty mkcd"
    fi
    
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

    # Default nvim config repo - can be overridden
    NVIM_CONFIG_REPO="${NVIM_CONFIG_REPO:-git@github.com:randalmurphal/neovim-config.git}"

    # Ensure nvim config directory exists
    mkdir -p "$HOME/.config"

    # Check if user wants to install nvim config
    if [ -d "$HOME/.config/nvim" ]; then
        # Check if it's already a git repo
        if [ -d "$HOME/.config/nvim/.git" ]; then
            print_success "Neovim configuration already installed as git repo"
            echo "Would you like to pull the latest changes? (y/n)"
            read -r pull_choice
            if [ "$pull_choice" = "y" ] || [ "$pull_choice" = "Y" ]; then
                cd "$HOME/.config/nvim"
                git pull origin main || git pull origin master || print_warning "Failed to pull latest changes"
                cd -
                print_success "Neovim config updated"
            fi
        else
            print_warning "Existing Neovim configuration found (not a git repo)"
            echo "Current nvim config will be backed up if replaced. What would you like to do?"
            echo "1. Keep existing configuration"
            echo "2. Replace with Randy's configuration (from git repo)"
            read -p "Choice (1 or 2): " nvim_choice

            if [ "$nvim_choice" = "2" ]; then
                # Create backup
                backup_dir="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"
                mv "$HOME/.config/nvim" "$backup_dir"
                print_info "Backup created: $backup_dir"

                # Clone nvim config
                print_info "Cloning nvim configuration from: $NVIM_CONFIG_REPO"
                if git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim"; then
                    print_success "Neovim configuration installed"
                else
                    print_error "Failed to clone nvim config repo"
                    print_info "You can manually clone it later:"
                    echo -e "  git clone $NVIM_CONFIG_REPO ~/.config/nvim"
                    # Restore backup
                    mv "$backup_dir" "$HOME/.config/nvim"
                    print_info "Restored original config from backup"
                fi
            else
                print_success "Keeping existing Neovim configuration"
            fi
        fi
    else
        print_info "No existing Neovim configuration found"
        echo "Would you like to install Randy's nvim configuration? (y/n)"
        read -r install_nvim
        if [ "$install_nvim" = "y" ] || [ "$install_nvim" = "Y" ]; then
            echo "Enter nvim config repo URL (or press Enter for default):"
            echo -e "Default: ${GREEN}$NVIM_CONFIG_REPO${NC}"
            read -r custom_repo
            if [ -n "$custom_repo" ]; then
                NVIM_CONFIG_REPO="$custom_repo"
            fi

            print_info "Cloning nvim configuration from: $NVIM_CONFIG_REPO"
            if git clone "$NVIM_CONFIG_REPO" "$HOME/.config/nvim"; then
                print_success "Neovim configuration installed"
                print_info "On first nvim launch, plugins will auto-install via lazy.nvim"
            else
                print_error "Failed to clone nvim config repo"
                print_info "You can manually clone it later:"
                echo -e "  git clone $NVIM_CONFIG_REPO ~/.config/nvim"
            fi
        else
            print_info "Skipping Neovim configuration"
        fi
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

# Change default shell to selected shell
change_default_shell() {
    if [ "$CHOSEN_SHELL" = "bash" ]; then
        print_info "Default shell will remain as bash"
        return 0
    fi
    
    print_header "SETTING ZSH AS DEFAULT SHELL"
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        print_info "Adding zsh to /etc/shells..."
        echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Check if user's shell is already zsh
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_success "Default shell is already zsh"
        return 0
    fi
    
    print_info "Changing default shell to zsh..."
    echo "You may need to enter your password to change the default shell."
    
    if chsh -s "$(which zsh)"; then
        print_success "Default shell changed to zsh"
        print_warning "You'll need to log out and back in for the change to take effect"
    else
        print_warning "Failed to change default shell. You can change it manually later with: chsh -s \$(which zsh)"
    fi
}

# Install Hack Nerd Font
install_nerd_font() {
    print_header "INSTALLING HACK NERD FONT"
    
    if [ "$OS_TYPE" = "macos" ]; then
        # Check if Hack Nerd Font is already installed via Homebrew
        if brew list --cask font-hack-nerd-font &> /dev/null 2>&1; then
            print_success "Hack Nerd Font already installed"
        else
            print_info "Installing Hack Nerd Font via Homebrew..."
            # Try with the new cask name format
            if brew install --cask font-hack-nerd-font 2>/dev/null; then
                print_success "Hack Nerd Font installed"
                print_info "You may need to change your terminal font to 'Hack Nerd Font'"
            else
                # Try alternative cask name
                print_info "Trying alternative font package name..."
                if brew install --cask font-hack-nerd-font 2>/dev/null || brew install font-hack-nerd-font 2>/dev/null; then
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
    if [ "$CHOSEN_SHELL" = "zsh" ]; then
        echo -e "1. ${CYAN}Reload your shell:${NC} source ~/.zshrc  ${YELLOW}(or open a new terminal)${NC}"
        echo -e "2. ${CYAN}If you changed shells:${NC} Log out and back in to use zsh by default"
    else
        if [ "$OS_TYPE" = "macos" ]; then
            echo -e "1. ${CYAN}Reload your shell:${NC} source ~/.bash_profile"
        else
            echo -e "1. ${CYAN}Reload your shell:${NC} source ~/.bashrc"
        fi
    fi
    echo -e "3. ${CYAN}Start tmux:${NC} tmux"
    echo -e "4. ${CYAN}Install tmux plugins:${NC} Ctrl+Space + I (in tmux)"
    echo -e "5. ${CYAN}Test your setup:${NC}"
    echo -e "   - cdsc               (go to system-configs)"
    echo -e "   - cdnv               (go to nvim config)"
    if [ "$CHOSEN_SHELL" = "zsh" ]; then
        echo -e "   - z <directory>      (smart cd with zoxide)"
        echo -e "   - zi                 (interactive directory search)"
    fi
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
     ██████╗  ██████╗ ███╗   ██╗███████╗██╗
     ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║
     ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║
     ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝
     ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗
     ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝ 
                                                       
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
    echo -e "• Shell selection (Zsh or Bash) with modern configurations"
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
    choose_shell
    get_repos_path
    get_python_venv
    select_components
    backup_configs

    # Conditional component installation
    if [ "$INSTALL_SYSTEM_PACKAGES" = "y" ]; then
        install_system_packages
    else
        print_info "Skipping system packages installation"
    fi

    if [ "$SETUP_SSH" = "y" ]; then
        setup_ssh_key
    else
        print_info "Skipping SSH key setup"
    fi

    clone_system_configs

    if [ "$SETUP_GIT" = "y" ]; then
        setup_git
    else
        print_info "Skipping Git configuration"
    fi

    if [ "$CHOSEN_SHELL" = "zsh" ] && [ "$SETUP_SHELL" = "y" ]; then
        install_oh_my_zsh
        fix_brew_completions
    fi

    if [ "$SETUP_SHELL" = "y" ]; then
        setup_shell_config
    else
        print_info "Skipping shell configuration"
    fi

    if [ "$SETUP_TMUX" = "y" ]; then
        setup_tmux
    else
        print_info "Skipping tmux configuration"
    fi

    if [ "$SETUP_NEOVIM" = "y" ]; then
        setup_neovim
    else
        print_info "Skipping Neovim configuration"
    fi

    if [ "$CHOSEN_SHELL" = "zsh" ] && [ "$SETUP_SHELL" = "y" ]; then
        change_default_shell
    fi

    if [ "$INSTALL_FONT" = "y" ]; then
        install_nerd_font
    else
        print_info "Skipping Nerd Font installation"
    fi

    show_final_instructions
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please don't run this script as root. Run as your regular user."
    exit 1
fi

# Run main function
main "$@"