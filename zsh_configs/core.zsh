# Core ZSH Configuration - oh-my-zsh, prompt, history, completions

# ========================================
# OH-MY-ZSH SETUP
# ========================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Using custom prompt below

# Fix Homebrew completions on macOS
if [[ "$OSTYPE" == "darwin"* ]] && type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    rm -f /usr/local/share/zsh/site-functions/_brew_cask 2>/dev/null
fi

# Dynamically load plugins based on what's available
plugins=()
[ -d "$ZSH/plugins/git" ] && plugins+=(git)
[ -d "$ZSH/plugins/python" ] && plugins+=(python)
[ -d "$ZSH/plugins/pip" ] && plugins+=(pip)
[ -d "$ZSH/plugins/docker" ] && plugins+=(docker)
[ -d "$ZSH/plugins/tmux" ] && plugins+=(tmux)
[ -d "$ZSH/plugins/fzf" ] && plugins+=(fzf)

# Check for custom plugins
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || [ -d "$ZSH/custom/plugins/zsh-autosuggestions" ]; then
    plugins+=(zsh-autosuggestions)
elif [ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || [ -d "$ZSH/custom/plugins/zsh-syntax-highlighting" ]; then
    plugins+=(zsh-syntax-highlighting)
elif [ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    ZSH_HIGHLIGHT_BREW=true
elif [ -f "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    ZSH_HIGHLIGHT_BREW=true
fi

source $ZSH/oh-my-zsh.sh

# Source brew-installed zsh-syntax-highlighting if needed (must be after oh-my-zsh)
if [ "$ZSH_HIGHLIGHT_BREW" = true ]; then
    if [ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [ -f "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
        source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
fi

# ========================================
# FZF INTEGRATION
# ========================================
# Ctrl+R = fuzzy history, Ctrl+T = fuzzy file finder, Alt+C = fuzzy cd
# Linux (apt install fzf)
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
# macOS (brew install fzf)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ========================================
# COMPLETION STYLING
# ========================================
zstyle ':completion:*' menu select                    # Arrow-navigable menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # Case insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # ls-style colors

# ========================================
# HISTORY SETTINGS
# ========================================
HISTSIZE=50000                   # Commands in memory
SAVEHIST=50000                   # Commands saved to file
HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY        # Write to file immediately (new tabs see it)
setopt HIST_IGNORE_ALL_DUPS      # No duplicates
setopt HIST_IGNORE_SPACE         # Prefix with space = not saved (for secrets)
setopt HIST_REDUCE_BLANKS        # Clean up whitespace

# ========================================
# ZSH-AUTOSUGGESTIONS CONFIG
# ========================================
# Ctrl+E = accept full suggestion, Ctrl+Right = accept next word
bindkey '^E' autosuggest-accept
bindkey '^[[1;5C' forward-word

# Context-aware suggestions: "what do I usually run after the previous command?"
ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd history)

# ========================================
# TERMINAL CWD REPORTING (OSC 7)
# ========================================
# Tells WezTerm the current directory so resurrect can restore pane locations
chpwd() { printf '\e]7;file://%s%s\e\\' "${HOST}" "${PWD}" }
chpwd  # Report on shell startup too

# ========================================
# CUSTOM PROMPT
# ========================================
git_branch() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    echo "%F{244}$branch%f"
  fi
}

virtualenv_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "%F{214}($(basename $VIRTUAL_ENV))%f"
  fi
}

setopt PROMPT_SUBST
export VIRTUAL_ENV_DISABLE_PROMPT=1
PROMPT='$(virtualenv_info)[%F{green}%n%f:%F{blue}%m%f]$(git_branch | sed "s/.*/:&/"):%F{magenta}%1~%f$ '

# ========================================
# ENVIRONMENT VARIABLES
# ========================================
# REPOS_PATH can be set before sourcing to override default
export REPOS_PATH="${REPOS_PATH:-$HOME/repos}"
export RUFF_CONFIG="$REPOS_PATH/system-configs/ruff.toml"
