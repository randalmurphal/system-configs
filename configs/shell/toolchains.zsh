# Language Toolchains - mise, nvm, Go, Rust, etc.
# Prioritizes mise if installed, falls back to legacy version managers

# ========================================
# MISE (Modern Version Manager - preferred)
# ========================================
# mise manages: node, python, go, rust, ruby, java, etc.
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# ========================================
# NVM (Legacy Node Version Manager)
# ========================================
# Only load nvm if mise is NOT managing node
if ! command -v mise &> /dev/null || ! mise current node &> /dev/null 2>&1; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# ========================================
# Go (Legacy paths - if not using mise)
# ========================================
# Only add Go paths if mise isn't managing Go
if ! command -v mise &> /dev/null || ! mise current go &> /dev/null 2>&1; then
    [ -d "$HOME/go-install/go/bin" ] && export PATH="$HOME/go-install/go/bin:$PATH"
fi

# GOPATH is always useful regardless of version manager
export GOPATH="${GOPATH:-$HOME/go}"
[ -d "$GOPATH/bin" ] && export PATH="$GOPATH/bin:$PATH"

# ========================================
# Rust (Cargo)
# ========================================
# Rust is typically installed via rustup, not mise
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# ========================================
# Python Virtual Environments
# ========================================
# Default system venv (set in options.conf or environment)
DEFAULT_VENV="${DEFAULT_VENV:-/opt/envs/py3.12}"

# Auto-activate default venv if it exists and no venv is already active
if [[ -z "$VIRTUAL_ENV" ]] && [[ -f "$DEFAULT_VENV/bin/activate" ]]; then
    source "$DEFAULT_VENV/bin/activate"
fi

# Helper function to quickly switch venvs
venv() {
    local venv_path="${1:-$DEFAULT_VENV}"

    # If just a name, look in /opt/envs
    if [[ ! "$venv_path" == /* ]] && [[ ! "$venv_path" == ./* ]]; then
        if [[ -d "/opt/envs/$venv_path" ]]; then
            venv_path="/opt/envs/$venv_path"
        elif [[ -d "./$venv_path" ]]; then
            venv_path="./$venv_path"
        fi
    fi

    if [[ -f "$venv_path/bin/activate" ]]; then
        source "$venv_path/bin/activate"
        echo "Activated: $venv_path (Python $(python --version 2>&1 | cut -d' ' -f2))"
    else
        echo "No venv found at: $venv_path"
        echo "Available in /opt/envs:"
        ls -1 /opt/envs 2>/dev/null || echo "  (none)"
        return 1
    fi
}
