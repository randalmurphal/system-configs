#!/usr/bin/env bash
# languages.sh - Programming language installation via mise
# Manages: Python, Node.js, Go, Rust, and more

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION - VERSION SPECIFICATIONS
# =============================================================================

# Python versions (space-separated, first is global default)
# Examples: "3.12" "3.12.8 3.11 3.14" "3.12 3.11.9 3.10"
LANG_PYTHON_VERSIONS="${LANG_PYTHON_VERSIONS:-${LANG_PYTHON_VERSION:-3.12}}"

# Virtual environment settings
# Default venv directory name (relative to project root)
LANG_VENV_DIR="${LANG_VENV_DIR:-.venv}"

# Additional venv paths for Claude to search (space-separated, relative paths)
# These are added to PATH in Claude's session
LANG_VENV_PATHS="${LANG_VENV_PATHS:-.venv venv .virtualenv}"

# Node.js version (use "lts" for LTS, "latest" for latest)
LANG_NODE_VERSION="${LANG_NODE_VERSION:-lts}"

# Go version
LANG_GO_VERSION="${LANG_GO_VERSION:-latest}"

# Rust (installed via rustup, not mise)
LANG_RUST_ENABLED="${LANG_RUST_ENABLED:-true}"

# Additional languages (space-separated, e.g., "ruby java")
LANG_ADDITIONAL="${LANG_ADDITIONAL:-}"

# Install global npm packages
LANG_NPM_GLOBALS="${LANG_NPM_GLOBALS:-typescript ts-node pnpm yarn}"

# Install global Python packages
LANG_PIP_GLOBALS="${LANG_PIP_GLOBALS:-pipx uv ruff}"

# Install global Go packages
LANG_GO_GLOBALS="${LANG_GO_GLOBALS:-}"

# =============================================================================
# MISE INSTALLATION
# =============================================================================

install_mise() {
    section "Installing mise (runtime version manager)"

    if cmd_exists mise; then
        local version
        version="$(mise --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        log_success "mise already installed (version $version)"
        return 0
    fi

    log_info "Installing mise..."

    # Install via official installer
    curl https://mise.run | sh

    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    if cmd_exists mise; then
        log_success "mise installed successfully"
    else
        log_error "mise installation failed"
        return 1
    fi
}

configure_mise_shell() {
    log_info "Configuring mise shell integration..."

    # ZSH: mise activation is handled by configs/shell/toolchains.zsh
    # which is sourced by the modular .zshrc. No modification needed.
    log_info "ZSH: mise activation included in toolchains.zsh"

    # Bash: Only modify if .bashrc is a regular file (not symlink to tracked file)
    local bashrc="$HOME/.bashrc"
    local mise_init_bash='eval "$(mise activate bash)"'

    if [[ -f "$bashrc" ]] && [[ ! -L "$bashrc" ]] && ! grep -q "mise activate" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# mise (runtime version manager)" >> "$bashrc"
        echo "$mise_init_bash" >> "$bashrc"
        log_success "Added mise activation to .bashrc"
    elif [[ -L "$bashrc" ]]; then
        log_info "Skipping .bashrc modification (symlink detected)"
    fi

    # Activate for current session
    eval "$(mise activate bash)" 2>/dev/null || true
}

# =============================================================================
# PYTHON INSTALLATION
# =============================================================================

install_python() {
    # Convert to array
    local versions=($LANG_PYTHON_VERSIONS)
    local default_version="${versions[0]}"

    section "Installing Python (${#versions[@]} version(s))"

    # Install build dependencies first
    install_python_build_deps

    # Install each version
    for version in "${versions[@]}"; do
        log_info "Installing Python $version via mise..."
        mise install "python@$version" || {
            log_warn "Failed to install Python $version"
            continue
        }
        log_success "Python $version installed"
    done

    # Set the first version as global default
    log_info "Setting Python $default_version as global default..."
    mise use --global "python@$default_version"

    # Verify installation
    local installed_version
    installed_version="$(mise exec -- python --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    log_success "Python $installed_version set as default"

    # Show all installed versions
    log_info "Installed Python versions:"
    mise list python 2>/dev/null | grep -E "^\s*python" || true

    # Install global packages (on default version)
    install_pip_globals

    # Install venv helper script
    install_venv_helper
}

install_venv_helper() {
    log_info "Installing venv helper script..."

    local helper_script="$HOME/.local/bin/mkvenv"
    ensure_dir "$(dirname "$helper_script")"

    cat > "$helper_script" << 'VENVEOF'
#!/usr/bin/env bash
# mkvenv - Create Python virtual environment with mise-managed Python
# Usage: mkvenv [python_version] [venv_dir]
#   mkvenv              # Use default Python, create .venv
#   mkvenv 3.11         # Use Python 3.11, create .venv
#   mkvenv 3.12 myenv   # Use Python 3.12, create ./myenv
#   mkvenv . myenv      # Use default Python, create ./myenv

set -euo pipefail

PYTHON_VERSION="${1:-.}"
VENV_DIR="${2:-.venv}"

# Expand "." to default (no version specification)
if [[ "$PYTHON_VERSION" == "." ]]; then
    PYTHON_VERSION=""
fi

# Check if mise is available
if ! command -v mise &>/dev/null; then
    echo "Error: mise not found. Install via: curl https://mise.run | sh"
    exit 1
fi

# Get Python executable
if [[ -n "$PYTHON_VERSION" ]]; then
    # Check if version is installed
    if ! mise list python 2>/dev/null | grep -q "$PYTHON_VERSION"; then
        echo "Python $PYTHON_VERSION not installed. Installing..."
        mise install "python@$PYTHON_VERSION"
    fi
    PYTHON_CMD="mise exec python@$PYTHON_VERSION -- python"
else
    PYTHON_CMD="mise exec -- python"
fi

# Get actual version for display
ACTUAL_VERSION=$($PYTHON_CMD --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

echo "Creating virtual environment..."
echo "  Python: $ACTUAL_VERSION"
echo "  Location: $VENV_DIR"

# Create venv
$PYTHON_CMD -m venv "$VENV_DIR"

# Upgrade pip in venv
"$VENV_DIR/bin/pip" install --upgrade pip --quiet

echo ""
echo "Virtual environment created!"
echo "Activate with: source $VENV_DIR/bin/activate"
VENVEOF

    chmod +x "$helper_script"
    log_success "Installed mkvenv helper at $helper_script"
    log_info "Usage: mkvenv [python_version] [venv_dir]"
}

install_python_build_deps() {
    log_info "Installing Python build dependencies..."

    case "$PKG_MANAGER" in
        apt)
            pkg_install_many build-essential libssl libbz2 libreadline libsqlite3 zlib liblzma libffi
            # Additional deps for full Python build
            sudo apt-get install -y -qq tk-dev libncursesw5-dev libxml2-dev libxmlsec1-dev 2>/dev/null || true
            ;;
        brew)
            pkg_install_many openssl readline sqlite xz zlib
            ;;
        dnf)
            pkg_install_many gcc zlib-devel bzip2-devel readline-devel sqlite-devel openssl-devel libffi-devel
            ;;
        zypper)
            pkg_install_many gcc make zlib-devel libbz2-devel readline-devel sqlite3-devel libopenssl-devel libffi-devel
            ;;
        pacman)
            pkg_install_many base-devel openssl zlib xz
            ;;
    esac
}

install_pip_globals() {
    if [[ -z "$LANG_PIP_GLOBALS" ]]; then
        return 0
    fi

    log_info "Installing global Python packages..."

    for pkg in $LANG_PIP_GLOBALS; do
        log_info "  Installing $pkg..."
        mise exec -- pip install --upgrade "$pkg" 2>/dev/null || log_warn "Failed to install $pkg"
    done

    log_success "Global Python packages installed"
}

# =============================================================================
# NODE.JS INSTALLATION
# =============================================================================

install_node() {
    section "Installing Node.js $LANG_NODE_VERSION"

    local node_spec="node@$LANG_NODE_VERSION"

    log_info "Installing Node.js via mise..."
    mise use --global "$node_spec"

    # Verify installation
    local installed_version
    installed_version="$(mise exec -- node --version 2>/dev/null)"
    log_success "Node.js $installed_version installed"

    # Install global packages
    install_npm_globals
}

install_npm_globals() {
    if [[ -z "$LANG_NPM_GLOBALS" ]]; then
        return 0
    fi

    log_info "Installing global npm packages..."

    for pkg in $LANG_NPM_GLOBALS; do
        log_info "  Installing $pkg..."
        mise exec -- npm install -g "$pkg" 2>/dev/null || log_warn "Failed to install $pkg"
    done

    log_success "Global npm packages installed"
}

# =============================================================================
# GO INSTALLATION
# =============================================================================

install_go() {
    section "Installing Go $LANG_GO_VERSION"

    log_info "Installing Go via mise..."
    mise use --global "go@$LANG_GO_VERSION"

    # Verify installation
    local installed_version
    installed_version="$(mise exec -- go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?')"
    log_success "$installed_version installed"

    # Setup GOPATH
    export GOPATH="$HOME/go"
    ensure_dir "$GOPATH/bin"

    # Install global Go packages
    install_go_globals
}

install_go_globals() {
    if [[ -z "$LANG_GO_GLOBALS" ]]; then
        return 0
    fi

    log_info "Installing global Go packages..."

    for pkg in $LANG_GO_GLOBALS; do
        log_info "  Installing $pkg..."
        mise exec -- go install "$pkg" 2>/dev/null || log_warn "Failed to install $pkg"
    done

    log_success "Global Go packages installed"
}

# =============================================================================
# RUST INSTALLATION (via rustup, not mise)
# =============================================================================

install_rust() {
    if [[ "$LANG_RUST_ENABLED" != "true" ]]; then
        log_skip "Rust installation disabled"
        return 0
    fi

    section "Installing Rust"

    if cmd_exists rustc; then
        local version
        version="$(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        log_success "Rust already installed (version $version)"

        # Update rustup
        log_info "Updating Rust toolchain..."
        rustup update stable 2>/dev/null || true
        return 0
    fi

    log_info "Installing Rust via rustup..."

    # Install rustup (non-interactive)
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Source cargo env for current session
    source "$HOME/.cargo/env" 2>/dev/null || true

    if cmd_exists rustc; then
        local version
        version="$(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        log_success "Rust $version installed"
    else
        log_error "Rust installation failed"
        return 1
    fi

    # Install common components
    log_info "Installing Rust components..."
    rustup component add clippy rustfmt rust-analyzer 2>/dev/null || true
}

# =============================================================================
# ADDITIONAL LANGUAGES
# =============================================================================

install_additional_languages() {
    if [[ -z "$LANG_ADDITIONAL" ]]; then
        return 0
    fi

    section "Installing Additional Languages"

    for lang in $LANG_ADDITIONAL; do
        log_info "Installing $lang..."
        mise use --global "$lang@latest" 2>/dev/null || log_warn "Failed to install $lang"
    done
}

# =============================================================================
# MISE CONFIGURATION FILE
# =============================================================================

create_mise_config() {
    section "Creating mise Configuration"

    local config_file="$HOME/.config/mise/config.toml"
    ensure_dir "$(dirname "$config_file")"

    if [[ -f "$config_file" ]]; then
        log_skip "mise config already exists at $config_file"
        return 0
    fi

    cat > "$config_file" << 'EOF'
# mise configuration
# https://mise.jdx.dev/configuration.html

[settings]
# Automatically install missing tools when entering a directory with .mise.toml
auto_install = true

# Always use the latest version of tools
legacy_version_file = true

# Show status message when switching versions
status = { show_tools = true }

# Experimental features
experimental = false
EOF

    log_success "Created mise config at $config_file"
}

# =============================================================================
# MAIN
# =============================================================================

install_languages() {
    install_mise
    configure_mise_shell
    create_mise_config

    # Install languages
    install_python
    install_node
    install_go
    install_rust
    install_additional_languages

    log_success "Language installations complete"
    log_info "Run 'mise doctor' to verify installations"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_languages
fi
