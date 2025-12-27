# lib/ - Bootstrap Library Functions

**Purpose**: Shared utilities for all bootstrap modules - logging, OS detection, package management, symlinks.

---

## Files

| File | Purpose | Key Exports |
|------|---------|-------------|
| `common.sh` | Core utilities | `log_*`, `cmd_exists`, `version_gte`, `detect_os`, `is_wsl` |
| `packages.sh` | Package manager abstraction | `pkg_install`, `pkg_update`, `PACKAGE_MAP` |
| `symlinks.sh` | Safe symlink management | `safe_symlink`, `backup_file`, `restore_backup` |

---

## Usage Pattern

All modules source these libraries:
```bash
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/packages.sh"
source "$SCRIPT_DIR/../lib/symlinks.sh"
```

---

## Key Functions

### common.sh

| Function | Purpose |
|----------|---------|
| `log_info/success/warn/error` | Colored logging |
| `section "Title"` | Section headers |
| `cmd_exists <cmd>` | Check if command exists |
| `version_gte "1.2" "1.0"` | Version comparison |
| `detect_os` | Returns: macos, debian, fedora, opensuse, arch |
| `is_wsl` | True if running in WSL |
| `ensure_dir <path>` | Create directory if missing |
| `download <url> <dest>` | Download via curl/wget |

### packages.sh

| Function | Purpose |
|----------|---------|
| `pkg_install <name>` | Install package (idempotent) |
| `pkg_install_many <...>` | Install multiple packages |
| `pkg_is_installed <name>` | Check if installed |
| `pkg_update` | Update package lists |
| `get_package_name <generic>` | Map to distro-specific name |

**Package mapping**: Use generic names (e.g., `bat`), `PACKAGE_MAP` translates to distro-specific (`batcat` on older apt).

### symlinks.sh

| Function | Purpose |
|----------|---------|
| `safe_symlink <src> <dest>` | Create symlink with backup |
| `backup_file <path>` | Backup existing file |
| `restore_backup <path>` | Restore from backup |

---

## Exported Variables

Set by `common.sh` on source:
- `BOOTSTRAP_DIR` - Root of bootstrap repo
- `CONFIGS_DIR` - `$BOOTSTRAP_DIR/configs`
- `DETECTED_OS` - macos, debian, fedora, opensuse, arch
- `DETECTED_DISTRO` - Specific distro ID (ubuntu, fedora, etc.)
- `DETECTED_ARCH` - amd64, arm64
- `IS_WSL` - "1" if WSL, "0" otherwise
- `PKG_MANAGER` - apt, brew, dnf, zypper, pacman

---

## Adding New Packages

To add cross-platform package support, update `PACKAGE_MAP` in `packages.sh`:

```bash
PACKAGE_MAP["mypackage"]="apt:mypackage,brew:mypackage,dnf:mypackage-name,zypper:mypackage,pacman:mypackage"
```

Empty value means not available: `brew:` skips on macOS.

---

## Idempotency

All functions are idempotent:
- `pkg_install` skips if already installed
- `safe_symlink` skips if link already correct
- `ensure_dir` skips if directory exists

Use `log_skip` for skipped operations.
