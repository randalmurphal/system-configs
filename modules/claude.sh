#!/usr/bin/env bash
# claude.sh - Claude Code CLI configuration and settings
#
# DESIGN PRINCIPLE: Claude Code must start fast with a clean, minimal environment.
# - Only PATH and Python venv activation
# - NO aliases, NO slow initializers (mise, nvm, pyenv, etc.)
# - NO fancy shell features that break in non-interactive mode

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

# Claude Code config directory
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# Install Claude Code if not present
CLAUDE_INSTALL="${CLAUDE_INSTALL:-true}"

# Clone config from GitHub (format: "username/repo", empty = use local/generated)
CLAUDE_CONFIG_REPO="${CLAUDE_CONFIG_REPO:-}"

# =============================================================================
# CLAUDE CODE INSTALLATION
# =============================================================================

install_claude_code() {
    if [[ "$CLAUDE_INSTALL" != "true" ]]; then
        log_skip "Claude Code installation disabled"
        return 0
    fi

    section "Installing Claude Code"

    if cmd_exists claude; then
        log_success "Claude Code already installed"

        # Check for updates
        log_info "Checking for updates..."
        npm update -g @anthropic-ai/claude-code 2>/dev/null || true
        return 0
    fi

    # Ensure npm is available
    if ! cmd_exists npm; then
        log_warn "npm not found. Install Node.js first (use languages module)"
        return 1
    fi

    log_info "Installing Claude Code via npm..."
    npm install -g @anthropic-ai/claude-code

    if cmd_exists claude; then
        log_success "Claude Code installed via npm"

        # Install local binary for better performance
        log_info "Installing local binary..."
        claude install 2>/dev/null || log_warn "Local binary install skipped (run 'claude install' manually)"

        # Add alias to use local binary (faster startup)
        add_claude_alias
    else
        log_error "Claude Code installation failed"
        return 1
    fi
}

add_claude_alias() {
    local zshrc="$HOME/.zshrc"
    local alias_line='alias claude="$HOME/.local/bin/claude"'

    # Check if alias already exists
    if grep -q 'alias claude=' "$zshrc" 2>/dev/null; then
        log_skip "Claude alias already in .zshrc"
        return 0
    fi

    # Add alias to zshrc
    cat >> "$zshrc" << 'EOF'

# Claude Code - use local binary for better performance
alias claude="$HOME/.local/bin/claude"
EOF
    log_success "Added claude alias to .zshrc"
}

# =============================================================================
# CLAUDE CONFIG FROM GITHUB
# =============================================================================

install_claude_config_github() {
    local repo="$1"

    section "Installing Claude Config from GitHub"

    if [[ -z "$repo" ]]; then
        log_info "No GitHub repo specified, using generated config"
        return 0
    fi

    local repo_url="git@github.com:${repo}.git"

    # Check if already cloned from same repo
    if [[ -d "$CLAUDE_CONFIG_DIR/.git" ]]; then
        local current_remote
        current_remote="$(git -C "$CLAUDE_CONFIG_DIR" remote get-url origin 2>/dev/null || echo "")"
        if [[ "$current_remote" == *"$repo"* ]]; then
            log_info "Config already cloned from $repo, pulling latest..."
            git -C "$CLAUDE_CONFIG_DIR" pull --rebase || log_warn "Pull failed, continuing with existing"
            return 0
        fi
    fi

    # Backup existing config
    if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
        log_info "Backing up existing Claude config..."
        mv "$CLAUDE_CONFIG_DIR" "$CLAUDE_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    log_info "Cloning $repo..."
    git clone "$repo_url" "$CLAUDE_CONFIG_DIR"

    log_success "Claude config installed from $repo"
}

# =============================================================================
# CLAUDE CODE SETTINGS
# =============================================================================

configure_claude_settings() {
    section "Configuring Claude Code Settings"

    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"
    ensure_dir "$CLAUDE_CONFIG_DIR"

    # If cloned from GitHub, don't overwrite
    if [[ -n "$CLAUDE_CONFIG_REPO" ]] && [[ -f "$settings_file" ]]; then
        log_skip "Settings from GitHub repo, not overwriting"
        return 0
    fi

    # Check if settings already exist
    if [[ -f "$settings_file" ]]; then
        log_info "Existing settings found, merging with defaults..."
        merge_claude_settings "$settings_file"
    else
        create_claude_settings "$settings_file"
    fi
}

create_claude_settings() {
    local settings_file="$1"

    log_info "Creating Claude Code settings..."

    # Detect Python venv path
    local venv_path=""
    local venv_bin=""
    if [[ -d "$HOME/.venv/py312" ]]; then
        venv_path="$HOME/.venv/py312"
        venv_bin="$venv_path/bin"
    elif [[ -d "$HOME/.venv/py311" ]]; then
        venv_path="$HOME/.venv/py311"
        venv_bin="$venv_path/bin"
    fi

    # Build PATH - include common binary locations (only if they exist)
    # Order matters: user bins first, then language-specific, then system
    local path_parts=""

    # User-level bins (highest priority)
    [[ -d "$HOME/.local/bin" ]] && path_parts="$HOME/.local/bin"
    [[ -n "$venv_bin" ]] && path_parts="${path_parts:+$path_parts:}$venv_bin"

    # Language toolchains
    [[ -d "$HOME/.cargo/bin" ]] && path_parts="${path_parts:+$path_parts:}$HOME/.cargo/bin"
    [[ -d "$HOME/go/bin" ]] && path_parts="${path_parts:+$path_parts:}$HOME/go/bin"
    [[ -d "$HOME/.npm-global/bin" ]] && path_parts="${path_parts:+$path_parts:}$HOME/.npm-global/bin"

    # Package managers (snap, flatpak)
    [[ -d "/snap/bin" ]] && path_parts="${path_parts:+$path_parts:}/snap/bin"
    [[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && path_parts="${path_parts:+$path_parts:}$HOME/.local/share/flatpak/exports/bin"
    [[ -d "/var/lib/flatpak/exports/bin" ]] && path_parts="${path_parts:+$path_parts:}/var/lib/flatpak/exports/bin"

    # System paths (always include)
    path_parts="${path_parts:+$path_parts:}/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    # Minimal settings: just PATH and VIRTUAL_ENV
    # NO hooks needed - VIRTUAL_ENV + PATH is sufficient for Python
    # NO aliases, NO slow initializers
    cat > "$settings_file" << EOF
{
  "env": {
    "PATH": "${path_parts}"${venv_path:+,
    "VIRTUAL_ENV": "$venv_path"}
  }
}
EOF

    log_success "Claude Code settings created at $settings_file"
    log_info "Minimal config: PATH + VIRTUAL_ENV only (no hooks, no aliases)"
}

merge_claude_settings() {
    local settings_file="$1"

    # Only add PATH if missing - don't overwrite user customizations
    if cmd_exists jq; then
        local tmp_file
        tmp_file="$(mktemp)"

        # Minimal merge: just ensure PATH has essential dirs
        jq --arg home "$HOME" \
           '.env.PATH //= ($home + "/.local/bin:/usr/local/bin:/usr/bin:/bin")' \
           "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

        log_success "Claude Code settings updated (minimal)"
    else
        log_warn "jq not available, skipping settings merge"
    fi
}

# =============================================================================
# STARTUP HOOKS (DISABLED - hooks are now inline in settings.json)
# =============================================================================

setup_startup_hooks() {
    # Hooks are now embedded directly in settings.json as a simple inline command
    # No external script needed - this keeps Claude Code startup fast and predictable
    #
    # The only hook we use: activate Python venv if present
    # Everything else (PATH, env vars) is in the static "env" section
    #
    # DO NOT add: mise, nvm, pyenv, cargo env, or any other slow initializers
    # Claude Code should start instantly with a clean, minimal environment

    log_skip "Startup hooks handled inline in settings.json (no external scripts)"
}

# =============================================================================
# CLAUDE.MD TEMPLATES
# =============================================================================

create_claude_md_template() {
    # Skip if using GitHub repo
    if [[ -n "$CLAUDE_CONFIG_REPO" ]]; then
        log_skip "Using GitHub config, skipping templates"
        return 0
    fi

    section "Creating CLAUDE.md Templates"

    local templates_dir="$CLAUDE_CONFIG_DIR/templates"
    ensure_dir "$templates_dir"

    # Global CLAUDE.md template
    local global_template="$templates_dir/CLAUDE.md.global"

    if [[ ! -f "$global_template" ]]; then
        cat > "$global_template" << 'EOF'
# Claude Work Contract

## Core Principles

**INVESTIGATE BEFORE MODIFYING**
Before changing shared code, check blast radius:
- Who calls this function/class?
- Who imports this module?
- What downstream consumers exist?
- What's NOT covered by tests?

**NO PARTIAL WORK:** Full implementation or explain why blocked.

**FAIL LOUD:** Errors surface with clear messages. Never catch and ignore.

**NO ASSUMPTIONS:** Tell me if you don't know something, are unsure, or disagree.

---

## Language Tools

**Python:** Run linting with `ruff check --fix` and type checking with `pyright`

**TypeScript:** Run `npm run lint` and `npm run typecheck`

**Rust:** Run `cargo clippy` and `cargo fmt`

**Go:** Run `go vet` and `gofmt`

---

## Task Completion Checklist

- [ ] Fully functional (no TODOs)
- [ ] Tests pass
- [ ] Linting clean
- [ ] Errors surface (no silent failures)
- [ ] No dead/commented code

---

## Git Safety

- NEVER force push to main/master
- NEVER skip pre-commit hooks
- NEVER amend commits already pushed
EOF

        log_success "Global CLAUDE.md template created at $global_template"
    else
        log_skip "Global CLAUDE.md template already exists"
    fi

    log_info "Templates available at $templates_dir"
}

# =============================================================================
# SKILLS SETUP
# =============================================================================

setup_claude_skills() {
    section "Setting Up Claude Skills"

    local skills_dir="$CLAUDE_CONFIG_DIR/skills"
    ensure_dir "$skills_dir"

    # Check if we have skills in our config
    local source_skills="$BOOTSTRAP_DIR/configs/claude/skills"

    if [[ -d "$source_skills" ]]; then
        log_info "Linking skills from system-configs..."
        for skill in "$source_skills"/*.md; do
            if [[ -f "$skill" ]]; then
                local skill_name
                skill_name="$(basename "$skill")"
                safe_symlink "$skill" "$skills_dir/$skill_name"
            fi
        done
        log_success "Skills linked"
    else
        log_info "No custom skills found in configs/claude/skills"
    fi
}

# =============================================================================
# MCP SERVERS CONFIGURATION
# =============================================================================

configure_mcp_servers() {
    section "Configuring MCP Servers"

    local mcp_config="$CLAUDE_CONFIG_DIR/mcp_servers.json"

    # Skip if using GitHub repo
    if [[ -n "$CLAUDE_CONFIG_REPO" ]] && [[ -f "$mcp_config" ]]; then
        log_skip "MCP config from GitHub repo"
        return 0
    fi

    if [[ -f "$mcp_config" ]]; then
        log_skip "MCP servers config already exists"
        return 0
    fi

    # Create default MCP servers config
    cat > "$mcp_config" << 'EOF'
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-filesystem"],
      "env": {}
    }
  }
}
EOF

    log_success "MCP servers config created at $mcp_config"
    log_info "Add additional MCP servers as needed"
}

# =============================================================================
# MAIN
# =============================================================================

install_claude() {
    install_claude_code

    # Clone from GitHub if specified
    if [[ -n "$CLAUDE_CONFIG_REPO" ]]; then
        install_claude_config_github "$CLAUDE_CONFIG_REPO"
    fi

    configure_claude_settings
    setup_startup_hooks
    create_claude_md_template
    setup_claude_skills
    configure_mcp_servers

    log_success "Claude Code configuration complete"
    log_info "Run 'claude' to start, or '/hooks' inside Claude to verify hook setup"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_claude
fi
