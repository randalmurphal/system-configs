# Language Toolchains - mise, nvm, Go, Rust, etc.
# Prioritizes mise if installed, falls back to legacy version managers

# ========================================
# MISE (Modern Version Manager - preferred)
# ========================================
# mise manages: node, python, go, rust, ruby, java, etc.
if command -v mise &> /dev/null; then
    # Clean up stale hooks from previous mise versions (prevents bash/zsh conflicts)
    # Old versions used _mise_hook, new versions use _mise_hook_precmd/_mise_hook_chpwd
    precmd_functions=( ${precmd_functions:#_mise_hook} )
    chpwd_functions=( ${chpwd_functions:#_mise_hook} )
    (( $+functions[_mise_hook] )) && unset -f _mise_hook

    eval "$(mise activate zsh)"
fi

# ========================================
# NVM (Legacy Node Version Manager) - LAZY LOADED
# ========================================
# Only load nvm if mise is NOT managing node
# NVM is lazy-loaded to avoid ~2 second shell startup penalty
if ! command -v mise &> /dev/null || ! mise which node &> /dev/null 2>&1; then
    export NVM_DIR="$HOME/.nvm"

    # Check if NVM is installed
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # Lazy-load NVM: load on first use of any node command
        _nvm_lazy_load() {
            # Prevent recursive calls - unset this function first
            unset -f _nvm_lazy_load 2>/dev/null
            # Remove stub functions so real commands take over
            unset -f nvm node npm npx yarn pnpm 2>/dev/null
            # Load NVM
            \. "$NVM_DIR/nvm.sh"
            [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
        }

        # Create stub functions - they load NVM then exec the real command
        nvm() { _nvm_lazy_load && nvm "$@"; }
        node() { _nvm_lazy_load && command node "$@"; }
        npm() { _nvm_lazy_load && command npm "$@"; }
        npx() { _nvm_lazy_load && command npx "$@"; }
        yarn() { _nvm_lazy_load && command yarn "$@"; }
        pnpm() { _nvm_lazy_load && command pnpm "$@"; }

        # If there's a default node version, add its bin to PATH immediately
        # This allows shebang scripts to find node without triggering lazy load
        if [[ -d "$NVM_DIR/versions/node" ]]; then
            local default_node
            default_node=$(cat "$NVM_DIR/alias/default" 2>/dev/null | head -1)
            if [[ -n "$default_node" ]]; then
                local node_version
                if [[ -d "$NVM_DIR/versions/node/$default_node" ]]; then
                    node_version="$default_node"
                else
                    node_version=$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | grep "^v${default_node}" | tail -1)
                fi
                if [[ -n "$node_version" && -d "$NVM_DIR/versions/node/$node_version/bin" ]]; then
                    export PATH="$NVM_DIR/versions/node/$node_version/bin:$PATH"
                fi
            fi
        fi
    fi
fi

# ========================================
# Go (Legacy paths - if not using mise)
# ========================================
# Only add Go paths if mise isn't managing Go
if ! command -v mise &> /dev/null || ! mise which go &> /dev/null 2>&1; then
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
