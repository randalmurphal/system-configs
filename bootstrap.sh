#!/usr/bin/env bash
# bootstrap.sh - System configuration bootstrap
# Cross-platform, modular, idempotent system setup
#
# Usage:
#   ./bootstrap.sh              # Interactive mode
#   ./bootstrap.sh --all        # Install everything
#   ./bootstrap.sh --module X   # Install specific module
#   ./bootstrap.sh --help       # Show help

# =============================================================================
# BASH VERSION CHECK (must run before anything else)
# =============================================================================
# Associative arrays require bash 4+. macOS ships with bash 3.2 (GPL2).
# If on macOS with old bash, try to use Homebrew's bash or fail with instructions.

if (( BASH_VERSINFO[0] < 4 )); then
    # Only macOS typically has this problem
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Try Homebrew bash locations
        for brew_bash in /opt/homebrew/bin/bash /usr/local/bin/bash; do
            if [[ -x "$brew_bash" ]]; then
                # Verify it's actually bash 4+
                if "$brew_bash" -c '(( BASH_VERSINFO[0] >= 4 ))' 2>/dev/null; then
                    exec "$brew_bash" "$0" "$@"
                fi
            fi
        done

        # No suitable bash found - give instructions
        echo "ERROR: This script requires bash 4+ (you have bash ${BASH_VERSION})"
        echo ""
        echo "macOS ships with an ancient bash due to licensing. To fix:"
        echo ""
        echo "  1. Install Homebrew (if not installed):"
        echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo ""
        echo "  2. Install modern bash:"
        echo "     brew install bash"
        echo ""
        echo "  3. Run this script again"
        echo ""
        exit 1
    else
        echo "ERROR: This script requires bash 4+ (you have bash ${BASH_VERSION})"
        exit 1
    fi
fi

set -euo pipefail

# =============================================================================
# INITIALIZATION
# =============================================================================

# Get script directory (resolve symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BOOTSTRAP_DIR="$SCRIPT_DIR"

# Source libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/symlinks.sh"

# Version
VERSION="1.0.0"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Load options file if exists
OPTIONS_FILE="${OPTIONS_FILE:-$SCRIPT_DIR/options.conf}"
if [[ -f "$OPTIONS_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$OPTIONS_FILE"
    log_info "Loaded options from $OPTIONS_FILE"
fi

# Available modules
MODULES=(
    "shell:ZSH, oh-my-zsh/zinit, plugins"
    "terminal:Tmux, TPM, WezTerm config"
    "editor:Neovim, LazyVim"
    "languages:mise, Python 3.12, Node.js, Go, Rust"
    "tools:Modern CLI (bat, eza, fzf, zoxide)"
    "git:Git configuration, SSH keys"
    "claude:Claude Code CLI settings"
)

# WSL-only module
if [[ "$IS_WSL" == "1" ]]; then
    MODULES+=("wsl:WSL optimizations and Windows integration")
fi

# Desktop modules (only show if applicable)
if [[ "$DETECTED_OS" != "macos" ]] && [[ "$IS_WSL" != "1" ]] && cmd_exists plasmashell; then
    MODULES+=("opensuse-plasma:Plasma 6 desktop configuration")
fi

# =============================================================================
# HELP
# =============================================================================

show_help() {
    cat << EOF
System Configs Bootstrap v${VERSION}

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help              Show this help message
  -a, --all               Install all modules (non-interactive)
  -m, --module MODULE     Install specific module
  -l, --list              List available modules
  -u, --update            Update existing installation
  -c, --config FILE       Use custom options file
  --dry-run               Show what would be done without doing it
  --no-color              Disable colored output

Available Modules:
EOF

    for module in "${MODULES[@]}"; do
        local name="${module%%:*}"
        local desc="${module#*:}"
        printf "  %-18s %s\n" "$name" "$desc"
    done

    cat << EOF

Examples:
  $(basename "$0")                    # Interactive mode
  $(basename "$0") --all              # Install everything
  $(basename "$0") -m shell -m tools  # Install specific modules
  $(basename "$0") --list             # Show available modules

Configuration:
  Create options.conf from options.example.conf to customize defaults.
  Environment variables can also override settings.

Environment Variables:
  LANG_PYTHON_VERSION     Python version (default: 3.12)
  LANG_NODE_VERSION       Node.js version (default: lts)
  EDITOR_NVIM_DISTRO      Neovim distribution (lazyvim, astronvim, nvchad)
  SHELL_PLUGIN_MANAGER    ZSH plugin manager (oh-my-zsh, zinit)

For more information, see the README.md
EOF
}

list_modules() {
    section "Available Modules"

    for module in "${MODULES[@]}"; do
        local name="${module%%:*}"
        local desc="${module#*:}"
        echo -e "  ${GREEN}$name${RESET}"
        echo -e "    ${DIM}$desc${RESET}"
        echo ""
    done
}

# =============================================================================
# MODULE RUNNER
# =============================================================================

run_module() {
    local module="$1"
    local module_file

    case "$module" in
        shell)
            module_file="$BOOTSTRAP_DIR/modules/shell.sh"
            ;;
        terminal)
            module_file="$BOOTSTRAP_DIR/modules/terminal.sh"
            ;;
        editor)
            module_file="$BOOTSTRAP_DIR/modules/editor.sh"
            ;;
        languages)
            module_file="$BOOTSTRAP_DIR/modules/languages.sh"
            ;;
        tools)
            module_file="$BOOTSTRAP_DIR/modules/tools.sh"
            ;;
        git)
            module_file="$BOOTSTRAP_DIR/modules/git.sh"
            ;;
        claude)
            module_file="$BOOTSTRAP_DIR/modules/claude.sh"
            ;;
        wsl)
            module_file="$BOOTSTRAP_DIR/modules/wsl.sh"
            ;;
        opensuse-plasma)
            module_file="$BOOTSTRAP_DIR/modules/desktop/opensuse-plasma.sh"
            ;;
        *)
            log_error "Unknown module: $module"
            return 1
            ;;
    esac

    if [[ ! -f "$module_file" ]]; then
        log_error "Module file not found: $module_file"
        return 1
    fi

    log_step "Running module: $module"
    # shellcheck source=/dev/null
    source "$module_file"

    # Call the install function (convention: install_<module_name>)
    local install_func="install_${module//-/_}"
    if declare -f "$install_func" > /dev/null; then
        "$install_func"
    else
        log_error "Install function not found: $install_func"
        return 1
    fi
}

# =============================================================================
# PREREQUISITES
# =============================================================================

check_prerequisites() {
    section "Checking Prerequisites"

    log_info "OS: $DETECTED_OS ($DETECTED_DISTRO)"
    log_info "Architecture: $DETECTED_ARCH"
    log_info "Package Manager: $PKG_MANAGER"

    if [[ "$IS_WSL" == "1" ]]; then
        log_info "Environment: WSL"
    fi

    # Check for required commands
    local required_cmds=(curl git)
    local missing=()

    for cmd in "${required_cmds[@]}"; do
        if ! cmd_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing required commands: ${missing[*]}"
        log_info "Installing prerequisites..."
        pkg_update
        pkg_install_many "${missing[@]}"
    fi

    # Check internet connectivity
    if ! has_internet; then
        log_warn "No internet connection detected. Some features may not work."
    fi

    log_success "Prerequisites check complete"
}

# =============================================================================
# INTERACTIVE MODE
# =============================================================================

interactive_mode() {
    section "System Configs Bootstrap v${VERSION}"

    echo -e "${BOLD}Welcome to the system configuration bootstrap!${RESET}"
    echo ""
    echo "Detected environment:"
    echo "  OS:           $DETECTED_OS ($DETECTED_DISTRO)"
    echo "  Architecture: $DETECTED_ARCH"
    echo "  Package Mgr:  $PKG_MANAGER"
    [[ "$IS_WSL" == "1" ]] && echo "  Environment:  WSL"
    echo ""

    check_prerequisites

    # Select modules to install
    section "Module Selection"

    local selected_modules=()

    echo "Select modules to install:"
    echo ""

    for module in "${MODULES[@]}"; do
        local name="${module%%:*}"
        local desc="${module#*:}"

        if confirm "Install $name ($desc)?"; then
            selected_modules+=("$name")
        fi
    done

    if [[ ${#selected_modules[@]} -eq 0 ]]; then
        log_warn "No modules selected. Exiting."
        exit 0
    fi

    # Confirm selection
    echo ""
    log_info "Selected modules: ${selected_modules[*]}"

    if ! confirm_yes "Proceed with installation?"; then
        log_info "Installation cancelled."
        exit 0
    fi

    # Update package lists
    section "Updating Package Lists"
    pkg_update

    # Run selected modules
    for module in "${selected_modules[@]}"; do
        run_module "$module"
    done

    # Summary
    section "Installation Complete"
    log_success "All selected modules have been installed!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Run 'nvim' to complete Neovim plugin installation"
    [[ "$IS_WSL" == "1" ]] && echo "  3. Run 'wsl --shutdown' in Windows Terminal to apply WSL changes"
    echo ""
    log_info "Configuration is stored in: $BOOTSTRAP_DIR"
    log_info "To update, run: git -C $BOOTSTRAP_DIR pull && ./bootstrap.sh --update"
}

# =============================================================================
# INSTALL ALL
# =============================================================================

install_all() {
    section "Installing All Modules"

    check_prerequisites
    pkg_update

    for module in "${MODULES[@]}"; do
        local name="${module%%:*}"
        run_module "$name"
    done

    section "Installation Complete"
    log_success "All modules installed!"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local mode="interactive"
    local modules_to_install=()
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_modules
                exit 0
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            -m|--module)
                if [[ -z "${2:-}" || "$2" == -* ]]; then
                    log_error "Module name required after -m/--module"
                    exit 1
                fi
                mode="specific"
                modules_to_install+=("$2")
                shift 2
                ;;
            -u|--update)
                mode="update"
                shift
                ;;
            -c|--config)
                if [[ -z "${2:-}" || "$2" == -* ]]; then
                    log_error "Config file path required after -c/--config"
                    exit 1
                fi
                OPTIONS_FILE="$2"
                if [[ -f "$OPTIONS_FILE" ]]; then
                    # shellcheck source=/dev/null
                    source "$OPTIONS_FILE"
                else
                    log_error "Config file not found: $OPTIONS_FILE"
                    exit 1
                fi
                shift 2
                ;;
            --dry-run)
                dry_run=true
                log_warn "Dry run mode - no changes will be made"
                shift
                ;;
            --no-color)
                RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE='' BOLD='' DIM='' RESET=''
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Execute based on mode
    case "$mode" in
        interactive)
            interactive_mode
            ;;
        all)
            install_all
            ;;
        specific)
            check_prerequisites
            pkg_update
            for module in "${modules_to_install[@]}"; do
                run_module "$module"
            done
            ;;
        update)
            log_info "Updating system-configs..."
            git -C "$BOOTSTRAP_DIR" pull
            log_success "Updated. Re-run bootstrap to apply changes."
            ;;
    esac
}

main "$@"
