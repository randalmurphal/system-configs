# configs/ - Dotfiles and Configuration Files

**Purpose**: Actual configuration files that get symlinked to `~/.config/` or `~/.*`. These are the dotfiles.

---

## Directory Structure

```
configs/
├── shell/          # ZSH configuration (modular)
├── tmux/           # Tmux configuration
├── wezterm/        # WezTerm terminal emulator + sysinfo daemon
├── nvim/           # Neovim config (if using local, otherwise cloned)
├── git/            # Git configuration templates
└── claude/         # Claude Code settings and skills
```

---

## Shell Configuration

**Location**: `configs/shell/`

| File | Purpose | Symlinked To |
|------|---------|--------------|
| `.zshrc` | Entry point, sources modules | `~/.zshrc` |
| `core.zsh` | oh-my-zsh setup, base config | sourced |
| `aliases.zsh` | Shell aliases | sourced |
| `functions.zsh` | Shell functions | sourced |
| `path.zsh` | PATH modifications | sourced |
| `toolchains.zsh` | mise, cargo, go paths | sourced |

**Architecture**: `.zshrc` sources all `*.zsh` files. Add new functionality by creating new `.zsh` files.

---

## Tmux Configuration

**Location**: `configs/tmux/`

| File | Symlinked To |
|------|--------------|
| `.tmux.conf` | `~/.tmux.conf` |

**Prefix**: `Ctrl+Space`

Key bindings defined in config. Uses TPM for plugins.

---

## WezTerm Configuration

**Location**: `configs/wezterm/`

| Item | Purpose |
|------|---------|
| `.wezterm.lua` | Main WezTerm config (Lua) |
| `sysinfo-daemon/` | Rust daemon for status bar metrics |

**sysinfo-daemon**: Polls system metrics and writes to file for WezTerm status bar. See `sysinfo-daemon/CLAUDE.md` for details.

---

## Git Configuration

**Location**: `configs/git/`

Templates for `.gitconfig`. The `git.sh` module handles user-specific setup (name, email).

---

## Claude Configuration

**Location**: `configs/claude/`

| Item | Purpose |
|------|---------|
| `skills/` | Custom Claude skills (symlinked to `~/.claude/skills/`) |

---

## Adding New Configs

1. Create directory under `configs/`
2. Add config files
3. Create/update module in `modules/` to handle symlinking
4. Use `safe_symlink "$CONFIGS_DIR/myconfig" "$HOME/.myconfig"`

---

## Modification Guidelines

- **DO** edit files here - they're the source of truth
- **DON'T** edit symlinked files in `~/` - changes should come here
- **DO** keep configs portable (no hardcoded paths like `/home/username`)
- **DO** use `$HOME` or relative paths in configs where possible

---

## Platform-Specific Configs

For platform-specific variations:
- Use conditionals within config files where supported (Lua, shell)
- Or create separate files: `config.linux.lua`, `config.macos.lua`
- The module handles which to symlink based on `$DETECTED_OS`
