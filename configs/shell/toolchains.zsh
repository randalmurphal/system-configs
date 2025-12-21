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
