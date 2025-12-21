#!/usr/bin/env bash
# claude.sh - Claude Code CLI configuration and settings

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

# Model preferences
CLAUDE_DEFAULT_MODEL="${CLAUDE_DEFAULT_MODEL:-sonnet}"

# Auto-compact settings
CLAUDE_AUTO_COMPACT="${CLAUDE_AUTO_COMPACT:-true}"
CLAUDE_AUTO_COMPACT_THRESHOLD="${CLAUDE_AUTO_COMPACT_THRESHOLD:-95}"

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
# CLAUDE CODE SETTINGS
# =============================================================================

configure_claude_settings() {
    section "Configuring Claude Code Settings"

    local settings_file="$CLAUDE_CONFIG_DIR/settings.json"
    ensure_dir "$CLAUDE_CONFIG_DIR"

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

    cat > "$settings_file" << EOF
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(mise *)",
      "Bash(cargo *)",
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
      "Bash(black *)",
      "Bash(mypy *)",
      "Bash(eslint *)",
      "Bash(prettier *)",
      "Bash(tsc *)"
    ],
    "deny": []
  },
  "preferences": {
    "model": "$CLAUDE_DEFAULT_MODEL",
    "customInstructions": "",
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

        # Merge autoCompact settings
        jq --arg enabled "$CLAUDE_AUTO_COMPACT" \
           --argjson threshold "$CLAUDE_AUTO_COMPACT_THRESHOLD" \
           '.autoCompact.enabled = ($enabled == "true") | .autoCompact.threshold = $threshold' \
           "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

        log_success "Claude Code settings updated"
    else
        log_warn "jq not available, skipping settings merge"
    fi
}

# =============================================================================
# CLAUDE.MD TEMPLATES
# =============================================================================

create_claude_md_template() {
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

    # Python project template
    local python_template="$templates_dir/CLAUDE.md.python"

    if [[ ! -f "$python_template" ]]; then
        cat > "$python_template" << 'EOF'
# Project: [PROJECT_NAME]

## Tech Stack
- Python 3.12+
- [Framework: FastAPI/Django/Flask]
- [Database: PostgreSQL/MongoDB]

## Commands
```bash
# Run tests
pytest

# Lint and format
ruff check --fix .
ruff format .

# Type check
pyright

# Run dev server
[command]
```

## Project Structure
```
src/
├── [module]/
│   ├── __init__.py
│   ├── models.py
│   └── services.py
tests/
└── [module]/
```

## Conventions
- Use type hints everywhere
- Docstrings for public functions
- Tests in tests/ mirror src/ structure
EOF

        log_success "Python CLAUDE.md template created at $python_template"
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
    configure_claude_settings
    create_claude_md_template
    setup_claude_skills
    configure_mcp_servers

    log_success "Claude Code configuration complete"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_claude
fi
