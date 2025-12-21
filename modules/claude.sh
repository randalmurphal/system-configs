#!/usr/bin/env bash
# claude.sh - Claude Code CLI configuration and settings
# Supports: Custom config from GitHub, startup hooks, multi-language environment

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

# Model preferences
CLAUDE_DEFAULT_MODEL="${CLAUDE_DEFAULT_MODEL:-sonnet}"

# Auto-compact settings
CLAUDE_AUTO_COMPACT="${CLAUDE_AUTO_COMPACT:-true}"
CLAUDE_AUTO_COMPACT_THRESHOLD="${CLAUDE_AUTO_COMPACT_THRESHOLD:-95}"

# Setup startup hooks for environment
CLAUDE_SETUP_HOOKS="${CLAUDE_SETUP_HOOKS:-true}"

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

    log_info "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code

    if cmd_exists claude; then
        log_success "Claude Code installed"
    else
        log_error "Claude Code installation failed"
        return 1
    fi
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
    local hooks_script="$CLAUDE_CONFIG_DIR/hooks/setup-env.sh"

    log_info "Creating Claude Code settings..."

    # Determine mise path
    local mise_path=""
    if [[ -f "$HOME/.local/bin/mise" ]]; then
        mise_path="$HOME/.local/bin"
    fi

    # Build env section with proper paths
    cat > "$settings_file" << EOF
{
  "env": {
    "PATH": "$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:\$PATH",
    "GOPATH": "$HOME/go",
    "RUST_BACKTRACE": "1",
    "NODE_OPTIONS": "--max-old-space-size=4096"
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$hooks_script"
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(pip *)",
      "Bash(pip3 *)",
      "Bash(uv *)",
      "Bash(mise *)",
      "Bash(cargo *)",
      "Bash(rustc *)",
      "Bash(rustup *)",
      "Bash(go *)",
      "Bash(ls *)",
      "Bash(cat *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(tree *)",
      "Bash(find *)",
      "Bash(grep *)",
      "Bash(rg *)",
      "Bash(fd *)",
      "Bash(fzf *)",
      "Bash(bat *)",
      "Bash(eza *)",
      "Bash(which *)",
      "Bash(pwd)",
      "Bash(echo *)",
      "Bash(mkdir *)",
      "Bash(touch *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(rm *)",
      "Bash(chmod *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Bash(jq *)",
      "Bash(make *)",
      "Bash(cmake *)",
      "Bash(docker *)",
      "Bash(nerdctl *)",
      "Bash(kubectl *)",
      "Bash(terraform *)",
      "Bash(pytest *)",
      "Bash(ruff *)",
      "Bash(pyright *)",
      "Bash(black *)",
      "Bash(mypy *)",
      "Bash(eslint *)",
      "Bash(prettier *)",
      "Bash(tsc *)",
      "Bash(pnpm *)",
      "Bash(yarn *)"
    ],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*credential*)",
      "Read(**/*secret*)"
    ]
  },
  "preferences": {
    "model": "$CLAUDE_DEFAULT_MODEL",
    "theme": "dark"
  },
  "autoCompact": {
    "enabled": $CLAUDE_AUTO_COMPACT,
    "threshold": $CLAUDE_AUTO_COMPACT_THRESHOLD
  },
  "telemetry": {
    "enabled": false
  }
}
EOF

    log_success "Claude Code settings created at $settings_file"
}

merge_claude_settings() {
    local settings_file="$1"

    # Only update specific fields without overwriting user customizations
    if cmd_exists jq; then
        local tmp_file
        tmp_file="$(mktemp)"

        # Merge autoCompact and add env if missing
        jq --arg enabled "$CLAUDE_AUTO_COMPACT" \
           --argjson threshold "$CLAUDE_AUTO_COMPACT_THRESHOLD" \
           --arg home "$HOME" \
           '.autoCompact.enabled = ($enabled == "true") |
            .autoCompact.threshold = $threshold |
            .env.PATH //= ($home + "/.local/bin:" + $home + "/.cargo/bin:" + $home + "/go/bin:$PATH") |
            .env.GOPATH //= ($home + "/go") |
            .env.RUST_BACKTRACE //= "1"' \
           "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

        log_success "Claude Code settings updated"
    else
        log_warn "jq not available, skipping settings merge"
    fi
}

# =============================================================================
# STARTUP HOOKS
# =============================================================================

setup_startup_hooks() {
    if [[ "$CLAUDE_SETUP_HOOKS" != "true" ]]; then
        log_skip "Startup hooks setup disabled"
        return 0
    fi

    section "Setting Up Claude Startup Hooks"

    local hooks_dir="$CLAUDE_CONFIG_DIR/hooks"
    ensure_dir "$hooks_dir"

    local hooks_script="$hooks_dir/setup-env.sh"

    # Create the environment setup script
    cat > "$hooks_script" << 'HOOKEOF'
#!/bin/bash
# Claude Code startup hook - sets up multi-language environment
# This script is called at session start and writes to CLAUDE_ENV_FILE

if [[ -z "$CLAUDE_ENV_FILE" ]]; then
    exit 0
fi

# mise (polyglot version manager) - preferred
if command -v mise &>/dev/null; then
    echo 'eval "$(mise activate bash)"' >> "$CLAUDE_ENV_FILE"
elif [[ -f "$HOME/.local/bin/mise" ]]; then
    echo 'eval "$($HOME/.local/bin/mise activate bash)"' >> "$CLAUDE_ENV_FILE"
fi

# Rust/Cargo
if [[ -f "$HOME/.cargo/env" ]]; then
    echo 'source "$HOME/.cargo/env"' >> "$CLAUDE_ENV_FILE"
fi

# Go
if [[ -d "$HOME/go/bin" ]]; then
    echo 'export GOPATH="$HOME/go"' >> "$CLAUDE_ENV_FILE"
    echo 'export PATH="$GOPATH/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
fi

# Node.js via nvm (fallback if mise not managing node)
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    if ! command -v mise &>/dev/null || ! mise current node &>/dev/null 2>&1; then
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$CLAUDE_ENV_FILE"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$CLAUDE_ENV_FILE"
    fi
fi

# Python via pyenv (fallback if mise not managing python)
if command -v pyenv &>/dev/null; then
    if ! command -v mise &>/dev/null || ! mise current python &>/dev/null 2>&1; then
        echo 'eval "$(pyenv init -)"' >> "$CLAUDE_ENV_FILE"
    fi
fi

# Ensure local bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"

# Project-local bins
echo 'export PATH="./node_modules/.bin:./venv/bin:./.venv/bin:$PATH"' >> "$CLAUDE_ENV_FILE"

exit 0
HOOKEOF

    chmod +x "$hooks_script"
    log_success "Startup hook created at $hooks_script"

    # Update settings to reference the hook
    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"
    if [[ -f "$settings_file" ]] && cmd_exists jq; then
        local tmp_file
        tmp_file="$(mktemp)"

        jq --arg script "$hooks_script" \
           '.hooks.SessionStart = [{"matcher": "startup", "hooks": [{"type": "command", "command": $script}]}]' \
           "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

        log_success "Settings updated with startup hook"
    fi
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
