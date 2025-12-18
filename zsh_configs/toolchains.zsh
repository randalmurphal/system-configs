# Language Toolchains - NVM, Go, etc.

# ========================================
# NVM (Node Version Manager)
# ========================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ========================================
# Go
# ========================================
[ -d "$HOME/go-install/go/bin" ] && export PATH="$HOME/go-install/go/bin:$PATH"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"
