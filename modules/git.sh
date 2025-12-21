#!/usr/bin/env bash
# git.sh - Git configuration and setup

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Git user config (can be overridden via environment or options.conf)
GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

# Default branch name
GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"

# Use delta for diffs
GIT_USE_DELTA="${GIT_USE_DELTA:-true}"

# Setup SSH key
GIT_SETUP_SSH="${GIT_SETUP_SSH:-true}"

# SSH key type
GIT_SSH_KEY_TYPE="${GIT_SSH_KEY_TYPE:-ed25519}"

# =============================================================================
# GIT INSTALLATION
# =============================================================================

install_git() {
    section "Installing Git"

    if cmd_exists git; then
        local version
        version="$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
        log_success "Git already installed (version $version)"
    else
        pkg_install git
    fi
}

# =============================================================================
# GIT CONFIGURATION
# =============================================================================

configure_git() {
    section "Configuring Git"

    # Get user info if not provided
    if [[ -z "$GIT_USER_NAME" ]]; then
        local current_name
        current_name="$(git config --global user.name 2>/dev/null || echo "")"
        if [[ -n "$current_name" ]]; then
            log_info "Current git user.name: $current_name"
            if ! confirm "Keep this name?"; then
                read -rp "Enter your name: " GIT_USER_NAME
            else
                GIT_USER_NAME="$current_name"
            fi
        else
            read -rp "Enter your name for git commits: " GIT_USER_NAME
        fi
    fi

    if [[ -z "$GIT_USER_EMAIL" ]]; then
        local current_email
        current_email="$(git config --global user.email 2>/dev/null || echo "")"
        if [[ -n "$current_email" ]]; then
            log_info "Current git user.email: $current_email"
            if ! confirm "Keep this email?"; then
                read -rp "Enter your email: " GIT_USER_EMAIL
            else
                GIT_USER_EMAIL="$current_email"
            fi
        else
            read -rp "Enter your email for git commits: " GIT_USER_EMAIL
        fi
    fi

    # Core settings
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"

    # Editor
    if cmd_exists nvim; then
        git config --global core.editor "nvim"
    elif cmd_exists vim; then
        git config --global core.editor "vim"
    fi

    # Diff and merge
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default

    # Delta integration
    if [[ "$GIT_USE_DELTA" == "true" ]] && cmd_exists delta; then
        configure_git_delta
    fi

    # Useful aliases
    configure_git_aliases

    # Pull behavior
    git config --global pull.rebase false

    # Push behavior
    git config --global push.default current
    git config --global push.autoSetupRemote true

    # Credential caching
    if is_macos; then
        git config --global credential.helper osxkeychain
    elif is_linux; then
        git config --global credential.helper cache
        git config --global credential.helper 'cache --timeout=86400'
    fi

    # Performance
    git config --global core.preloadindex true
    git config --global core.fscache true

    # Line endings (cross-platform)
    git config --global core.autocrlf input

    # Color
    git config --global color.ui auto

    log_success "Git configured"
}

configure_git_delta() {
    log_info "Configuring git-delta..."

    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.light false
    git config --global delta.line-numbers true
    git config --global delta.side-by-side false
    git config --global delta.syntax-theme "Dracula"

    # Merge conflict display
    git config --global merge.conflictstyle diff3
    git config --global delta.merge-conflict-style-bold true

    log_success "git-delta configured"
}

configure_git_aliases() {
    log_info "Configuring git aliases..."

    # Status and log
    git config --global alias.st "status -sb"
    git config --global alias.lg "log --oneline --graph --all --decorate"
    git config --global alias.ll "log --pretty=format:'%C(yellow)%h%Creset %s %C(cyan)<%an>%Creset %C(green)(%cr)%Creset' --abbrev-commit"
    git config --global alias.last "log -1 HEAD --stat"

    # Branch management
    git config --global alias.br "branch -vv"
    git config --global alias.bra "branch -a -vv"
    git config --global alias.bd "branch -d"
    git config --global alias.bD "branch -D"

    # Checkout/switch
    git config --global alias.co "checkout"
    git config --global alias.sw "switch"
    git config --global alias.swc "switch -c"

    # Commit
    git config --global alias.ci "commit"
    git config --global alias.ca "commit --amend"
    git config --global alias.can "commit --amend --no-edit"

    # Diff
    git config --global alias.df "diff"
    git config --global alias.dfs "diff --staged"
    git config --global alias.dfw "diff --word-diff"

    # Reset
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.uncommit "reset --soft HEAD~1"

    # Stash
    git config --global alias.stl "stash list"
    git config --global alias.stp "stash pop"
    git config --global alias.sts "stash show -p"

    # Remote
    git config --global alias.pu "push"
    git config --global alias.puf "push --force-with-lease"
    git config --global alias.pl "pull"
    git config --global alias.fe "fetch --all --prune"

    # Worktree
    git config --global alias.wt "worktree"
    git config --global alias.wtl "worktree list"
    git config --global alias.wta "worktree add"
    git config --global alias.wtr "worktree remove"

    # Maintenance
    git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"

    log_success "Git aliases configured"
}

# =============================================================================
# SSH KEY SETUP
# =============================================================================

setup_ssh_key() {
    if [[ "$GIT_SETUP_SSH" != "true" ]]; then
        log_skip "SSH key setup disabled"
        return 0
    fi

    section "Setting Up SSH Key"

    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_$GIT_SSH_KEY_TYPE"

    ensure_dir "$ssh_dir"
    chmod 700 "$ssh_dir"

    if [[ -f "$key_file" ]]; then
        log_success "SSH key already exists: $key_file"
        log_info "Public key:"
        cat "${key_file}.pub"
        return 0
    fi

    if ! confirm "Generate new SSH key ($GIT_SSH_KEY_TYPE)?"; then
        log_skip "SSH key generation skipped"
        return 0
    fi

    local email="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null || echo "")}"
    if [[ -z "$email" ]]; then
        read -rp "Enter email for SSH key: " email
    fi

    log_info "Generating SSH key..."
    ssh-keygen -t "$GIT_SSH_KEY_TYPE" -C "$email" -f "$key_file" -N ""

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add "$key_file" 2>/dev/null || true

    # Configure SSH
    configure_ssh

    log_success "SSH key generated"
    echo ""
    log_info "Public key (add to GitHub/GitLab):"
    echo ""
    cat "${key_file}.pub"
    echo ""
}

configure_ssh() {
    local ssh_config="$HOME/.ssh/config"

    # Create or update SSH config
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << EOF
# SSH Configuration

Host *
    AddKeysToAgent yes
    IdentitiesOnly yes

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_$GIT_SSH_KEY_TYPE

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_$GIT_SSH_KEY_TYPE
EOF
        chmod 600 "$ssh_config"
        log_success "SSH config created"
    else
        log_skip "SSH config already exists"
    fi
}

# =============================================================================
# GITIGNORE GLOBAL
# =============================================================================

setup_global_gitignore() {
    section "Setting Up Global Gitignore"

    local gitignore="$HOME/.gitignore_global"

    if [[ -f "$gitignore" ]]; then
        log_skip "Global gitignore already exists"
    else
        cat > "$gitignore" << 'EOF'
# Global gitignore

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini

# Editor directories and files
.idea/
.vscode/
*.swp
*.swo
*~
*.sublime-workspace
.project
.settings/

# Environment files
.env
.env.local
.env.*.local

# Python
__pycache__/
*.py[cod]
*.pyo
.Python
*.egg-info/
.eggs/
*.egg
.mypy_cache/
.pytest_cache/
.ruff_cache/
venv/
.venv/

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.o
*.so
*.dylib

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
*.temp
EOF

        git config --global core.excludesfile "$gitignore"
        log_success "Global gitignore created at $gitignore"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

install_git_module() {
    install_git
    configure_git
    setup_global_gitignore
    setup_ssh_key
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_git_module
fi
