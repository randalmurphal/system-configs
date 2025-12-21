#!/usr/bin/env bash
# symlinks.sh - Safe symlink management with backups

# Source common if not already loaded
if [[ -z "${BOOTSTRAP_DIR:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# =============================================================================
# CONFIGURATION
# =============================================================================

# Backup directory for replaced files
BACKUP_DIR="${BACKUP_DIR:-$HOME/.config-backups}"
BACKUP_TIMESTAMP="${BACKUP_TIMESTAMP:-$(date +%Y%m%d_%H%M%S)}"

# =============================================================================
# SYMLINK OPERATIONS
# =============================================================================

# Create a symlink safely, backing up existing files
# Usage: safe_symlink <source> <target>
safe_symlink() {
    local source="$1"
    local target="$2"

    # Resolve to absolute paths
    source="$(cd "$(dirname "$source")" && pwd)/$(basename "$source")"

    # Expand ~ in target
    target="${target/#\~/$HOME}"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source does not exist: $source"
        return 1
    fi

    # Ensure parent directory exists
    local target_dir
    target_dir="$(dirname "$target")"
    ensure_dir "$target_dir"

    # Check if target is already correct symlink
    if [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink -f "$target")"
        if [[ "$current_target" == "$source" ]]; then
            log_skip "Symlink already correct: $target -> $source"
            return 0
        else
            # Wrong symlink, remove it
            log_info "Updating symlink: $target"
            rm "$target"
        fi
    elif [[ -e "$target" ]]; then
        # Target exists and is not a symlink - back it up
        backup_file "$target"
    fi

    # Create the symlink
    ln -s "$source" "$target"
    log_success "Created symlink: $target -> $source"
}

# Backup a file before replacing
backup_file() {
    local file="$1"

    # Don't backup symlinks (just remove them)
    if [[ -L "$file" ]]; then
        rm "$file"
        return 0
    fi

    # Create backup directory if needed
    ensure_dir "$BACKUP_DIR/$BACKUP_TIMESTAMP"

    # Determine backup path (preserve directory structure)
    local relative_path="${file#$HOME/}"
    local backup_path="$BACKUP_DIR/$BACKUP_TIMESTAMP/$relative_path"

    # Ensure backup parent directory exists
    ensure_dir "$(dirname "$backup_path")"

    # Move file to backup
    mv "$file" "$backup_path"
    log_info "Backed up: $file -> $backup_path"
}

# Remove a symlink if it points to our configs
safe_unlink() {
    local target="$1"
    target="${target/#\~/$HOME}"

    if [[ ! -L "$target" ]]; then
        log_skip "Not a symlink: $target"
        return 0
    fi

    local link_target
    link_target="$(readlink -f "$target")"

    # Only remove if it points to our config directory
    if [[ "$link_target" == "$BOOTSTRAP_DIR"* ]]; then
        rm "$target"
        log_success "Removed symlink: $target"

        # Restore backup if exists
        restore_backup "$target"
    else
        log_warn "Symlink does not point to system-configs, skipping: $target"
    fi
}

# Restore a file from backup
restore_backup() {
    local file="$1"
    file="${file/#\~/$HOME}"

    local relative_path="${file#$HOME/}"

    # Find most recent backup
    local latest_backup=""
    for backup_dir in "$BACKUP_DIR"/*/; do
        if [[ -e "$backup_dir$relative_path" ]]; then
            latest_backup="$backup_dir$relative_path"
        fi
    done

    if [[ -n "$latest_backup" && -e "$latest_backup" ]]; then
        mv "$latest_backup" "$file"
        log_success "Restored from backup: $file"
    fi
}

# =============================================================================
# BATCH SYMLINK OPERATIONS
# =============================================================================

# Link all files in a directory to a target directory
# Usage: link_directory <source_dir> <target_dir> [pattern]
link_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local pattern="${3:-*}"

    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory does not exist: $source_dir"
        return 1
    fi

    ensure_dir "$target_dir"

    for file in "$source_dir"/$pattern; do
        if [[ -e "$file" ]]; then
            local basename
            basename="$(basename "$file")"
            safe_symlink "$file" "$target_dir/$basename"
        fi
    done
}

# Link dotfiles from a directory (files starting with .)
# Usage: link_dotfiles <source_dir> <target_dir>
link_dotfiles() {
    local source_dir="$1"
    local target_dir="${2:-$HOME}"

    link_directory "$source_dir" "$target_dir" ".*"
}

# =============================================================================
# CONFIG FILE OPERATIONS
# =============================================================================

# Append content to a file if not already present
# Usage: append_if_missing <file> <marker> <content>
append_if_missing() {
    local file="$1"
    local marker="$2"
    local content="$3"

    # Expand ~ in file path
    file="${file/#\~/$HOME}"

    # Create file if it doesn't exist
    if [[ ! -f "$file" ]]; then
        ensure_dir "$(dirname "$file")"
        touch "$file"
    fi

    # Check if marker already exists
    if grep -qF "$marker" "$file" 2>/dev/null; then
        log_skip "Already present in $file: $marker"
        return 0
    fi

    # Append content
    echo "" >> "$file"
    echo "$content" >> "$file"
    log_success "Added to $file"
}

# Source a file from shell rc if not already sourcing
# Usage: add_source_to_rc <rc_file> <source_file> [comment]
add_source_to_rc() {
    local rc_file="$1"
    local source_file="$2"
    local comment="${3:-Sourced by system-configs}"

    # Expand paths
    rc_file="${rc_file/#\~/$HOME}"
    source_file="${source_file/#\~/$HOME}"

    # Create marker line
    local marker="source \"$source_file\""

    # Content to add
    local content
    content="# $comment
if [[ -f \"$source_file\" ]]; then
    source \"$source_file\"
fi"

    append_if_missing "$rc_file" "$marker" "$content"
}

# =============================================================================
# VERIFICATION
# =============================================================================

# List all symlinks managed by system-configs
list_managed_symlinks() {
    log_info "Symlinks pointing to $BOOTSTRAP_DIR:"
    echo ""

    # Common locations to check
    local locations=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
        "$HOME/.wezterm.lua"
        "$HOME/.gitconfig"
    )

    for loc in "${locations[@]}"; do
        if [[ -L "$loc" ]]; then
            local target
            target="$(readlink -f "$loc")"
            if [[ "$target" == "$BOOTSTRAP_DIR"* ]]; then
                echo -e "  ${GREEN}$loc${RESET} -> $target"
            fi
        fi
    done

    # Also check .config directory
    if [[ -d "$HOME/.config" ]]; then
        while IFS= read -r -d '' link; do
            local target
            target="$(readlink -f "$link")"
            if [[ "$target" == "$BOOTSTRAP_DIR"* ]]; then
                echo -e "  ${GREEN}$link${RESET} -> $target"
            fi
        done < <(find "$HOME/.config" -maxdepth 2 -type l -print0 2>/dev/null)
    fi
}

# Verify all symlinks are valid
verify_symlinks() {
    local errors=0

    log_info "Verifying symlinks..."

    while IFS= read -r -d '' link; do
        local target
        target="$(readlink "$link")"
        if [[ ! -e "$link" ]]; then
            log_error "Broken symlink: $link -> $target"
            ((errors++))
        fi
    done < <(find "$HOME" -maxdepth 3 -type l -print0 2>/dev/null)

    if [[ $errors -eq 0 ]]; then
        log_success "All symlinks valid"
    else
        log_warn "Found $errors broken symlinks"
    fi

    return $errors
}

# =============================================================================
# CLEANUP
# =============================================================================

# List available backups
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "No backups found"
        return
    fi

    log_info "Available backups:"
    for backup in "$BACKUP_DIR"/*/; do
        if [[ -d "$backup" ]]; then
            local timestamp
            timestamp="$(basename "$backup")"
            local count
            count="$(find "$backup" -type f | wc -l)"
            echo "  $timestamp ($count files)"
        fi
    done
}

# Clean old backups (keep last N)
clean_old_backups() {
    local keep="${1:-5}"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        return
    fi

    local count=0
    for backup in $(ls -1dr "$BACKUP_DIR"/*/); do
        ((count++))
        if [[ $count -gt $keep ]]; then
            log_info "Removing old backup: $(basename "$backup")"
            rm -rf "$backup"
        fi
    done
}
