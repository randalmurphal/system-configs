# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ========================================
# PYTHON VIRTUAL ENVIRONMENT
# ========================================

# Activate Python virtual environment if it exists
if [ -f "VENV_PATH_PLACEHOLDER/bin/activate" ]; then
    source "VENV_PATH_PLACEHOLDER/bin/activate"
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'


# ========================================
# FUNCTIONAL PROMPT OPTIONS
# ========================================
# 
#        ░█▀▀█ ░█▀▀█ ░█▄─░█ ░█▀▀▄ █──█ ▀ ░█▀▀▀
#        ░█▄▄▀ ░█▄▄█ ░█░█░█ ░█─░█ █▄▄█ ▀ ░█▀▀▀
#        ░█─░█ ░█─░█ ░█──▀█ ░█▄▄▀ ▄▄▄█ ▀ ░█▄▄▄
#            ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗ █████╗ ██╗     
#            ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗██║     
#               ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║███████║██║     
#               ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██╔══██║██║     
#               ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██║  ██║███████╗
#               ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
#                     ███████╗██╗   ██╗██████╗ ███████╗██████╗ ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ 
#                     ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗
#                     ███████╗██║   ██║██████╔╝█████╗  ██████╔╝██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝
#                     ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗
#                     ███████║╚██████╔╝██║     ███████╗██║  ██║██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║
#                     ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝
#

# Function to get git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Function to get git status indicators
parse_git_dirty() {
    local status=$(git status --porcelain 2> /dev/null)
    if [[ -n $status ]]; then
        echo " ±"
    fi
}

# Function to show last command execution time
timer_start() {
    timer=${timer:-$SECONDS}
}

timer_stop() {
    timer_show=$(($SECONDS - $timer))
    unset timer
}

trap 'timer_start' DEBUG
PROMPT_COMMAND='timer_stop'

# CHOOSE ONE OF THESE PROMPTS (uncomment the one you prefer):

# Option 1: Minimal functional prompt
# PS1="\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[1;32m\]\$(parse_git_branch)\[\033[1;31m\]\$(parse_git_dirty)\[\033[0m\] $ "

# Option 2: Two-line detailed prompt
# PS1='┌─[\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\]] [\[\033[1;33m\]\w\[\033[0m\]]\[\033[1;32m\]$(parse_git_branch)\[\033[1;31m\]$(parse_git_dirty)\[\033[0m\] [\[\033[1;35m\]\t\[\033[0m\]]\n└─\[\033[1;32m\]❯\[\033[0m\] '

# Option 3: Arrow-style prompt
# PS1="\[\033[1;34m\]➜\[\033[0m\] \[\033[1;36m\]\u\[\033[0m\] \[\033[1;33m\]\W\[\033[1;32m\]\$(parse_git_branch)\[\033[1;31m\]\$(parse_git_dirty)\[\033[0m\] "

# Option 4: Time-aware prompt with execution duration
# PS1="\[\033[1;30m\][\${timer_show}s] \[\033[1;36m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\]:\[\033[1;33m\]\w\[\033[1;32m\]\$(parse_git_branch)\[\033[1;31m\]\$(parse_git_dirty)\[\033[0m\] $ "

# Custom prompt: [user:host]:(git-branch):/curr_directory $
PS1="[\[\033[1;32m\]\u\[\033[0m\]:\[\033[1;34m\]\h\[\033[0m\]]:\[\033[1;30m\]\$(parse_git_branch)\[\033[0m\]:\[\033[1;35m\]\W\[\033[0m\] $ "

# ========================================
# ADDITIONAL IMPROVEMENTS
# ========================================

# Better history settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
shopt -s histappend

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 RANDY'S EPIC ALIASES - BECAUSE LIFE'S TOO SHORT FOR LONG COMMANDS 🚀
# ═══════════════════════════════════════════════════════════════════════════════

# Navigation shortcuts - 🧭 Directory surfing made easy
alias ls='ls -la --color=auto'        # 📂 List all files with colors
alias ..='cd ..'                      # ⬆️  Go up one directory  
alias ...='cd ../..'                  # ⬆️⬆️ Go up two directories
alias ....='cd ../../..'              # ⬆️⬆️⬆️ Go up three directories (because why not?)

# File operations - 📁 File management wizardry
alias tree='tree -C'                  # 🌳 Colorful directory tree
alias df='df -h'                      # 💽 Disk space in human format
alias du='du -h'                      # 📊 Directory sizes in human format
alias free='free -h'                  # 🧠 Memory usage in human format
alias grep='grep --color=auto'        # 🔍 Colorful text searching
alias mkdir='mkdir -pv'               # 📁 Create directories with feedback
alias wget='wget -c'                  # 🌐 Resume downloads automatically

# System info shortcuts - 📊 Quick system stats
alias path='echo -e ${PATH//:/\\n}'   # 🛤️  Show PATH in readable format
alias now='date +"%T"'                # 🕐 Current time
alias nowtime=now                     # 🕐 Time alias (because redundancy rocks)
alias nowdate='date +"%d-%m-%Y"'      # 📅 Current date

# Git shortcuts - 🐙 Git wizardry at your fingertips
alias gs='git status'                 # 📊 Show git status
alias ga='git add'                    # ➕ Add files to staging
alias gc='git commit'                 # 💾 Commit changes
alias gp='git push'                   # 🚀 Push to remote
alias gl='git log --oneline'          # 📜 Compact git history
alias gd='git diff'                   # 🔍 Show differences
alias gb='git branch'                 # 🌿 List branches
alias gco='git checkout'              # 🔄 Switch branches/checkout

# Safety net aliases - 🛡️ Protection from "oops" moments
alias rm='rm -i'                      # 🗑️  Confirm before deleting
alias cp='cp -i'                      # 📋 Confirm before overwriting
alias mv='mv -i'                      # 🚚 Confirm before moving

# Extract function for various archive types
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

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find and kill process by name
killp() {
    ps aux | grep $1 | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick web server in current directory
serve() {
    python3 -m http.server ${1:-8000}
}

# Repos path - modify this for different systems
export REPOS_PATH="$HOME/repos"

# Python development tools configuration
export RUFF_CONFIG="$REPOS_PATH/system-configs/ruff.toml"

# Show colorized keybindings reference
alias keys="$REPOS_PATH/system-configs/show-keys"

# Quick navigation aliases
alias cdsc="cd $REPOS_PATH/system-configs"
alias cdnv="cd ~/.config/nvim"

# Use neovim instead of vim
alias vim='nvim'
alias vi='nvim'

# ========================================
# TMUX AUTO-START
# ========================================

# Auto-start tmux session "main" on interactive shell startup
# Only if we're not already in a tmux session and tmux is available
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    # Check if session "main" exists
    if tmux has-session -t main 2>/dev/null; then
        # Session exists, attach to it
        exec tmux attach-session -t main
    else
        # Session doesn't exist, create and attach
        exec tmux new-session -s main
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
#           🔮 MODERN TOOL REPLACEMENTS - LEVEL UP YOUR CLI GAME! 🔮
# ═══════════════════════════════════════════════════════════════════════════════
#     ██████╗ ██╗   ██╗███████╗████████╗    ██████╗ ██╗   ██╗███████╗████████╗██╗
#     ██╔══██╗██║   ██║██╔════╝╚══██╔══╝    ██╔══██╗██║   ██║██╔════╝╚══██╔══╝██║
#     ██████╔╝██║   ██║███████╗   ██║       ██████╔╝██║   ██║███████╗   ██║   ██║
#     ██╔══██╗██║   ██║╚════██║   ██║       ██╔══██╗██║   ██║╚════██║   ██║   ╚═╝
#     ██║  ██║╚██████╔╝███████║   ██║       ██████╔╝╚██████╔╝███████║   ██║   ██╗
#     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝       ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   ╚═╝

# 🎯 Smart upgrades - Only if the tools are installed
command -v bat >/dev/null 2>&1 && alias cat='bat --style=plain'     # 🦇 Syntax highlighting cat
command -v exa >/dev/null 2>&1 && alias ls='exa -la --git'          # 📂 Better ls with git status
command -v fd >/dev/null 2>&1 && alias find='fd'                    # 🔍 Blazing fast file finder
command -v rg >/dev/null 2>&1 && alias grep='rg'                    # ⚡ Ripgrep - grep on steroids
command -v dust >/dev/null 2>&1 && alias du='dust'                  # 🌪️  Better disk usage analyzer
command -v htop >/dev/null 2>&1 && alias top='htop'                 # 📊 Interactive process viewer
command -v gping >/dev/null 2>&1 && alias ping='gping'              # 📈 Graph-based ping

# ========================================
# ENHANCED HISTORY SEARCH
# ========================================

# hstr integration for better history search
if command -v hstr >/dev/null 2>&1; then
    export HSTR_CONFIG=hicolor
    bind '"\C-r": "\C-a hstr -- \C-j"'
fi


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
