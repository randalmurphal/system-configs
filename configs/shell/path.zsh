# PATH Additions - portable across machines
# Order matters: last added = first in PATH (prepending)
# So we add in reverse priority order

# Lowest priority first
[ -d "/snap/bin" ] && export PATH="/snap/bin:$PATH"

# Homebrew: Intel, then ARM (ARM ends up first = higher priority on Apple Silicon)
[ -d "/usr/local/bin" ] && export PATH="/usr/local/bin:$PATH"
[ -d "/opt/homebrew/bin" ] && export PATH="/opt/homebrew/bin:$PATH"

# User toolchains
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# User local bins - highest priority
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi
