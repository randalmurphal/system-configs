# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""  # Empty to use custom prompt

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  python
  pip
  docker
  tmux
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ========================================
# CUSTOM PROMPT CONFIGURATION
# ========================================
# Must be AFTER sourcing oh-my-zsh to override any theme settings

# Function to get git branch
git_branch() {
  git branch 2>/dev/null | grep '^*' | colrm 1 2
}

# Function to get virtualenv name with orange color
virtualenv_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "%F{214}($(basename $VIRTUAL_ENV))%f"
  fi
}

# Custom prompt matching bash style exactly
# Format: (venv) [user:host]:(git-branch):curr_dir $
setopt PROMPT_SUBST
export VIRTUAL_ENV_DISABLE_PROMPT=1
PROMPT='$(virtualenv_info)[%F{green}%n%f:%F{blue}$(hostname)%f]:%F{8}$(git_branch)%f:%F{magenta}%1~%f$ '

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# ========================================
# MIGRATED FROM BASH CONFIGURATION
# ========================================

# Python Virtual Environment
if [ -f "VENV_PATH_PLACEHOLDER/bin/activate" ]; then
    source "VENV_PATH_PLACEHOLDER/bin/activate"
fi

# Custom Functions
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

# Find and kill process by name
killp() {
    ps aux | grep $1 | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick web server in current directory
serve() {
    python3 -m http.server ${1:-8000}
}

# Environment Variables
export REPOS_PATH="REPOS_PATH_PLACEHOLDER"
export RUFF_CONFIG="$REPOS_PATH/system-configs/ruff.toml"

# Quick navigation aliases
alias cdsc="cd $REPOS_PATH/system-configs"
alias cdnv="cd ~/.config/nvim"

# Smart nvim function - prefer snap version, fallback to system
nvim() {
    if [ -x "/snap/bin/nvim" ]; then
        /snap/bin/nvim "$@"
    elif [ -x "/usr/bin/nvim" ]; then
        /usr/bin/nvim "$@"
    else
        echo "nvim not found"
        return 1
    fi
}

alias vim='nvim'
alias vi='nvim'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ls='eza -la --git'

# Modern CLI aliases - Cross-platform support
alias ll='eza -la --git'
alias la='eza -la --git'
alias lt='eza -la --tree --git'
alias tree='eza --tree'

# Cross-platform bat alias
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
    alias bat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

# Cross-platform fd alias  
if command -v fdfind >/dev/null 2>&1; then
    alias find='fdfind'
    alias fd='fdfind'
elif command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# ========================================
# CARGO PATH (for Rust tools like eza)
# ========================================
export PATH="$HOME/.cargo/bin:$PATH"

# ========================================
# ZOXIDE (smarter cd)
# ========================================
eval "$(zoxide init zsh)"

# ========================================
# TMUX AUTO-START
# ========================================

# Auto-start tmux session "main" on interactive shell startup
# Only in "primary" terminal sessions (not IDE integrated terminals or nested shells)
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ -n "$PS1" ] && [ "$SHLVL" -eq 1 ]; then
    # Check if session "main" exists
    if tmux has-session -t main 2>/dev/null; then
        # Session exists, attach to it
        exec tmux attach-session -t main
    else
        # Session doesn't exist, create and attach
        exec tmux new-session -s main
    fi
fi


