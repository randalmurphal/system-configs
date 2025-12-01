# Randy's ZSH Configuration - Portable across Linux/macOS

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
export REPOS_PATH="$HOME/repos"
export RUFF_CONFIG="$REPOS_PATH/system-configs/ruff.toml"

# ========================================
# ALIASES
# ========================================

# Editor
alias vim='nvim'
alias vi='nvim'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias gd='git diff'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cdsc="cd $REPOS_PATH/system-configs"
alias cdnv="cd ~/.config/nvim"

# Claude shortcuts
alias claude="~/.claude/local/claude --dangerously-skip-permissions"
alias c="claude"

# OS-specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    alias ls='ls -laG'
    alias ll='ls -laG'
    alias la='ls -laG'

    if command -v bat &> /dev/null; then
        alias cat='bat'
    fi

    if command -v rg &> /dev/null; then
        alias grep='rg'
    fi

    if command -v gdu &> /dev/null; then
        alias du='gdu'
        alias ncdu='gdu'
    elif command -v ncdu &> /dev/null; then
        alias du='ncdu'
    fi
else
    # Linux
    alias ls='ls -la --color=auto'
    alias ll='ls -la --color=auto'
    alias la='ls -la --color=auto'

    if command -v batcat &> /dev/null; then
        alias cat='batcat'
        alias bat='batcat'
    elif command -v bat &> /dev/null; then
        alias cat='bat'
    fi

    if command -v rg &> /dev/null; then
        alias grep='rg'
    fi

    if command -v gdu &> /dev/null; then
        alias du='gdu'
        alias ncdu='gdu'
    elif command -v ncdu &> /dev/null; then
        alias du='ncdu'
    fi
fi

# ========================================
# FUNCTIONS
# ========================================
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# ========================================
# PATH ADDITIONS
# ========================================
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"
[ -d "/opt/homebrew/bin" ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "/usr/local/bin" ] && export PATH="/usr/local/bin:$PATH"
[ -d "/snap/bin" ] && export PATH="/snap/bin:$PATH"

# ========================================
# ZOXIDE (smarter cd)
# ========================================
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi
