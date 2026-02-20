# WezTerm Config - Agent Guide

## File Location

| Platform | Config Location | Actual File |
|----------|-----------------|-------------|
| Windows+WSL | `C:\Users\rmurphy\.wezterm.lua` | Copy from WSL source |
| WSL (source) | `~/repos/system-configs/configs/wezterm/.wezterm.lua` | Edit this one |

**Always edit the WSL source file.** On WSL systems, WezTerm runs as a Windows process and reads from the Windows-side path (`C:\Users\rmurphy\.wezterm.lua`). After editing, copy the file to the Windows side:

```bash
cp ~/repos/system-configs/configs/wezterm/.wezterm.lua /mnt/c/Users/rmurphy/.wezterm.lua
```

If you skip this, WezTerm will keep running the old config.

## Config Structure

```lua
-- Plugins (resurrect.wezterm for session persistence)
-- Core settings (WSL domain, GPU acceleration)
-- Theme colors (dark purple matching nvim)
-- Font settings (JetBrains Mono)
-- Leader key config (Ctrl+Space)
-- Key bindings (config.keys table)
-- Copy mode key table (config.key_tables.copy_mode)
-- Mouse bindings
-- Scrollback settings
-- Status bar (right side, time/date)
-- Session persistence hooks
```

## Common Modifications

### Adding a keybinding

Add to `config.keys` table:
```lua
{ key = 'x', mods = 'LEADER', action = act.SomeAction },
```

For shift: `mods = 'LEADER|SHIFT'`

### Custom action with callback

```lua
{ key = 'x', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)
  -- lua code here
end) },
```

### Moving panes between tabs

No native Lua API for moving to existing tabs. Use CLI workaround:
```lua
wezterm.run_child_process({
  'wezterm', 'cli', 'split-pane',
  '--move-pane-id', source_pane_id,
  '--pane-id', target_pane_id,
  '--right'  -- or --left, --top, --bottom
})
```

### Pane selection UI

```lua
act.PaneSelect {
  mode = 'SwapWithActive',  -- or 'Activate'
  alphabet = '1234567890',  -- custom labels
}
```

### Input selector (menu picker)

```lua
window:perform_action(wezterm.action.InputSelector {
  title = "Pick something",
  choices = { { id = "1", label = "Option 1" }, ... },
  action = wezterm.action_callback(function(win, pane, id, label)
    if id then
      -- user selected something
    end
  end),
}, pane)
```

## Testing Changes

1. Edit `~/repos/system-configs/configs/wezterm/.wezterm.lua`
2. Copy to Windows side: `cp ~/repos/system-configs/configs/wezterm/.wezterm.lua /mnt/c/Users/rmurphy/.wezterm.lua`
3. In WezTerm: `Leader + r` to reload
4. If syntax error: check WezTerm's debug overlay (`Leader + ?`)

## Known Limitations

- **No layout toggle**: Can't switch horizontal<->vertical split (unlike tmux)
- **resurrect.wezterm Windows bugs**: May flicker cmd.exe windows, occasional hangs
- **No pane-to-existing-tab in Lua API**: Must use CLI workaround

## Dependencies

- WezTerm nightly (for latest features)
- resurrect.wezterm plugin (auto-downloaded on first load)
- JetBrains Mono font
