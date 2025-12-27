# modules/ - Bootstrap Installation Modules

**Purpose**: Self-contained installation modules. Each handles one domain (shell, editor, languages, etc.).

---

## Module Overview

| Module | What It Installs | Key Options |
|--------|-----------------|-------------|
| `shell.sh` | ZSH, oh-my-zsh/zinit, plugins | `SHELL_PLUGIN_MANAGER`, `SHELL_PLUGINS` |
| `terminal.sh` | tmux, TPM, WezTerm config | `TERMINAL_INSTALL_TPM`, `TERMINAL_INSTALL_PLUGINS` |
| `editor.sh` | Neovim, config (LazyVim/custom), fonts | `EDITOR_NVIM_DISTRO`, `EDITOR_NVIM_REPO` |
| `languages.sh` | mise, Python, Node, Go, Rust | `LANG_PYTHON_VERSION`, `LANG_NODE_VERSION` |
| `tools.sh` | CLI tools (bat, eza, fzf, zoxide, etc.) | `TOOLS_CORE`, `TOOLS_ENHANCED`, `TOOLS_DEV` |
| `claude.sh` | Claude Code CLI, settings, MCP | `CLAUDE_INSTALL`, `CLAUDE_DEFAULT_MODEL` |
| `wsl.sh` | WSL optimizations, clipboard, wrappers | `WSL_SYSTEMD`, `WSL_WINDOWS_INTEROP` |
| `desktop/opensuse-plasma.sh` | Rofi, KWin config (openSUSE only) | `PLASMA_INSTALL_ROFI` |

---

## Module Structure

Every module follows this pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"

# Configuration with defaults
MY_OPTION="${MY_OPTION:-default_value}"

# Installation functions
install_thing() {
    section "Installing Thing"
    # ... idempotent installation logic
}

# Main entry point
install_module_name() {
    install_thing
    # ...
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_module_name
fi
```

---

## Adding a New Module

1. Create `modules/mymodule.sh` following the structure above
2. Add configuration options to `options.example.conf`
3. Register in `bootstrap.sh`:
   - Add to `MODULES` array
   - Add case in `run_module()`
4. Update root `CLAUDE.md` module table

---

## Key Design Patterns

### Idempotency
- Check before installing: `if cmd_exists X; then log_skip; return; fi`
- Use `pkg_install` (auto-skips if installed)
- Use `safe_symlink` (auto-skips if correct)

### Configuration
- All options via environment variables with defaults
- Options can come from `options.conf` or command line

### Error Handling
- `set -euo pipefail` at top
- Use `log_error` for failures
- Return non-zero on failure

### Cross-Platform
- Check `$DETECTED_OS` for OS-specific logic
- Check `$IS_WSL` for WSL-specific behavior
- Use `pkg_install` with generic names (auto-maps)

---

## Module Dependencies

```
tools.sh ─────────────────────────────┐
shell.sh ─────────────────────────────┤
terminal.sh ──────────────────────────┼──> lib/*.sh (common, packages, symlinks)
editor.sh ────────────────────────────┤
languages.sh ─────────────────────────┤
claude.sh ──────> languages.sh (npm)  │
wsl.sh ───────────────────────────────┘
```

`claude.sh` requires npm (from `languages.sh`) for Claude Code installation.

---

## Testing a Module

Run individual module:
```bash
./bootstrap.sh -m shell      # Run just shell module
./modules/shell.sh           # Or execute directly
```

Dry run (check what would happen):
```bash
DEBUG=1 ./bootstrap.sh -m shell  # Verbose output
```
