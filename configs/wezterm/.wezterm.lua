-- WezTerm config - designed for Randy's workflow
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- =============================================================================
-- PLUGINS
-- =============================================================================

local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- =============================================================================
-- CORE SETTINGS
-- =============================================================================

-- Default to WSL on Windows, native shell on Linux
if wezterm.target_triple:find('windows') then
  config.default_domain = 'WSL:Ubuntu'
end

-- Performance
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'

-- =============================================================================
-- DARK PURPLE THEME (matching your nvim setup)
-- =============================================================================
-- bg-dark: #050505 | bg-surface: #121218 | bg-elevated: #1a1a2e
-- purple-primary: #9d4edd | text-primary: #e0e0e0 | text-dim: #606060

config.colors = {
  foreground = '#e0e0e0',
  background = '#050505',
  cursor_bg = '#9d4edd',
  cursor_fg = '#050505',
  cursor_border = '#9d4edd',
  selection_fg = '#ffffff',
  selection_bg = '#5a189a',
  split = '#9d4edd',
  scrollbar_thumb = '#606060',

  ansi = {
    '#121218',  -- black
    '#ff6b6b',  -- red
    '#4ecdc4',  -- green
    '#ffe66d',  -- yellow
    '#9d4edd',  -- blue (purple primary)
    '#ff6b9d',  -- magenta
    '#4ecdc4',  -- cyan
    '#e0e0e0',  -- white
  },
  brights = {
    '#606060',  -- bright black
    '#ff8a8a',  -- bright red
    '#7ee8e0',  -- bright green
    '#fff49c',  -- bright yellow
    '#b87aff',  -- bright blue
    '#ff8abc',  -- bright magenta
    '#7ee8e0',  -- bright cyan
    '#ffffff',  -- bright white
  },

  tab_bar = {
    background = '#121218',
    active_tab = {
      bg_color = '#9d4edd',
      fg_color = '#050505',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#121218',
      fg_color = '#606060',
    },
    inactive_tab_hover = {
      bg_color = '#1a1a2e',
      fg_color = '#e0e0e0',
    },
    new_tab = {
      bg_color = '#121218',
      fg_color = '#606060',
    },
    new_tab_hover = {
      bg_color = '#9d4edd',
      fg_color = '#050505',
    },
  },
}

-- Window appearance
config.window_background_opacity = 1.0
config.window_padding = {
  left = 4,
  right = 4,
  top = 4,
  bottom = 4,
}

-- Tab bar at top (like your tmux)
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

-- Inactive panes - dim but keep colors vibrant
config.inactive_pane_hsb = {
  hue = 1.0,
  saturation = 1.05,   -- Slightly boost saturation to compensate for brightness loss
  brightness = 0.55,   -- Noticeably dimmer
}

-- =============================================================================
-- FOCUS-AWARE WINDOW EFFECTS
-- =============================================================================
-- Tier 1: Lua-based effects (works on Windows+WSL and Linux)
-- Tier 2: GPU shader effects (Linux with dedicated GPU only - requires source mod)

local is_linux = wezterm.target_triple:find('linux')
local has_gpu = is_linux  -- Assume Linux = dedicated GPU for now

-- Focus state styling
local focus_config = {
  -- When window is focused
  focused = {
    opacity = 1.0,
    -- background_image = nil,  -- Could set a path here
  },
  -- When window loses focus
  unfocused = {
    opacity = 0.85,
    -- background_image = '/path/to/unfocused-bg.png',  -- Optional
  },
}

-- GPU-enhanced config (Linux only) - placeholder for future source mods
if has_gpu then
  focus_config.gpu_effects = {
    enabled = false,  -- Set true when shader mods are ready
    unfocused_animation = 'subtle_noise',  -- Future: noise, pulse, matrix, etc.
    blur_radius = 5,
  }
end

-- Apply focus changes dynamically (Linux only - Windows/WSL has perf issues with config overrides)
if is_linux then
  wezterm.on('window-focus-changed', function(window, pane)
    local overrides = window:get_config_overrides() or {}

    if window:is_focused() then
      -- === FOCUSED STATE ===
      overrides.window_background_opacity = 1.0
      overrides.foreground_text_hsb = nil  -- Normal text brightness
    else
      -- === UNFOCUSED STATE ===
      overrides.window_background_opacity = 0.88

      -- Dim text brightness only, keep full saturation (no pastel bullshit)
      overrides.foreground_text_hsb = {
        hue = 1.0,         -- Keep hue unchanged
        saturation = 1.0,  -- Keep saturation full
        brightness = 0.7,  -- Just dim it
      }
    end

    window:set_config_overrides(overrides)
  end)
end

-- =============================================================================
-- FONT
-- =============================================================================

config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 11.0
config.line_height = 1.1

-- =============================================================================
-- LEADER KEY (Ctrl+Space) - for less frequent operations
-- =============================================================================

config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }

-- =============================================================================
-- KEYBINDINGS (data-driven for dynamic help popup)
-- =============================================================================

-- Complex callback actions (defined separately for readability)
local actions = {
  break_pane_to_tab = wezterm.action_callback(function(window, pane)
    local tab, _ = pane:move_to_new_tab()
    tab:activate()
  end),

  bring_pane_from_tab = wezterm.action_callback(function(window, pane)
    local current_tab_id = window:active_tab():tab_id()
    local choices = {}
    for _, mux_win in ipairs(wezterm.mux.all_windows()) do
      for _, tab in ipairs(mux_win:tabs()) do
        if tab:tab_id() ~= current_tab_id then
          for _, p in ipairs(tab:panes()) do
            local label = string.format("[Tab %d] %s", tab:tab_id(), p:get_title())
            table.insert(choices, { id = tostring(p:pane_id()), label = label })
          end
        end
      end
    end
    if #choices == 0 then
      window:toast_notification('WezTerm', 'No panes in other tabs', nil, 2000)
      return
    end
    window:perform_action(wezterm.action.InputSelector {
      title = "Select pane to bring here",
      choices = choices,
      action = wezterm.action_callback(function(inner_win, inner_pane, id, label)
        if id then
          wezterm.run_child_process({
            'wezterm', 'cli', 'split-pane',
            '--move-pane-id', id,
            '--pane-id', tostring(inner_pane:pane_id()),
            '--right'
          })
        end
      end),
    }, pane)
  end),

  save_layout = wezterm.action_callback(function(win, pane)
    local state = resurrect.workspace_state.get_workspace_state()
    resurrect.state_manager.save_state(state, "default_layout")
    win:toast_notification('WezTerm', 'Default layout saved', nil, 2000)
  end),

  restore_layout = wezterm.action_callback(function(win, pane)
    local state = resurrect.state_manager.load_state("default_layout", "workspace")
    if state then
      resurrect.workspace_state.restore_workspace(state, {
        window = win,
        relative = true,
        restore_text = true,
      })
      win:toast_notification('WezTerm', 'Default layout restored', nil, 2000)
    else
      win:toast_notification('WezTerm', 'No default layout saved yet (use Leader+Shift+S)', nil, 3000)
    end
  end),
}

-- Keybinding definitions: { key, mods, action, desc, group }
-- Groups: nav, scrollback, clipboard, splits, tabs, panes, copymode, search, session, other
local keybind_defs = {
  -- Navigation
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left', desc = 'Navigate pane left', group = 'nav' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down', desc = 'Navigate pane down', group = 'nav' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up', desc = 'Navigate pane up', group = 'nav' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right', desc = 'Navigate pane right', group = 'nav' },
  { key = 'h', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(-1), desc = 'Previous tab', group = 'nav' },
  { key = 'l', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(1), desc = 'Next tab', group = 'nav' },

  -- Scrollback snap
  { key = 'c', mods = 'CTRL', action = act.Multiple { act.ScrollToBottom, act.SendKey { key = 'c', mods = 'CTRL' } }, desc = 'Snap to bottom + SIGINT', group = 'scrollback' },
  { key = 'l', mods = 'CTRL', action = act.Multiple { act.ScrollToBottom, act.SendKey { key = 'l', mods = 'CTRL' } }, desc = 'Snap to bottom + clear', group = 'scrollback' },

  -- Clipboard
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard', desc = 'Copy to clipboard', group = 'clipboard' },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard', desc = 'Paste from clipboard', group = 'clipboard' },

  -- Splits
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' }, desc = 'Split right', group = 'splits' },
  { key = 'V', mods = 'LEADER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' }, desc = 'Split down', group = 'splits' },

  -- Tabs
  { key = 'n', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain', desc = 'New tab', group = 'tabs' },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true }, desc = 'Close pane', group = 'tabs' },
  { key = 'X', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true }, desc = 'Close tab', group = 'tabs' },
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0), desc = 'Go to tab 1', group = 'tabs' },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1), desc = 'Go to tab 2', group = 'tabs' },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2), desc = 'Go to tab 3', group = 'tabs' },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3), desc = 'Go to tab 4', group = 'tabs' },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4), desc = 'Go to tab 5', group = 'tabs' },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5), desc = 'Go to tab 6', group = 'tabs' },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6), desc = 'Go to tab 7', group = 'tabs' },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7), desc = 'Go to tab 8', group = 'tabs' },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8), desc = 'Go to tab 9', group = 'tabs' },

  -- Panes
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState, desc = 'Zoom pane toggle', group = 'panes' },
  { key = 'a', mods = 'LEADER', action = actions.break_pane_to_tab, desc = 'Break pane to new tab', group = 'panes' },
  { key = 'b', mods = 'LEADER', action = actions.bring_pane_from_tab, desc = 'Bring pane from other tab', group = 'panes' },
  { key = 'p', mods = 'LEADER', action = act.PaneSelect { mode = 'SwapWithActive', alphabet = '1234567890' }, desc = 'Swap panes (picker)', group = 'panes' },
  { key = '{', mods = 'LEADER|SHIFT', action = act.RotatePanes 'CounterClockwise', desc = 'Rotate panes CCW', group = 'panes' },
  { key = '}', mods = 'LEADER|SHIFT', action = act.RotatePanes 'Clockwise', desc = 'Rotate panes CW', group = 'panes' },

  -- Copy mode & search
  { key = 'k', mods = 'LEADER', action = act.ActivateCopyMode, desc = 'Enter copy mode (vim nav)', group = 'copymode' },
  { key = 'f', mods = 'LEADER', action = act.Search 'CurrentSelectionOrEmptyString', desc = 'Search scrollback', group = 'search' },
  { key = 'g', mods = 'LEADER', action = act.SendString 'nvim -c "lua require(\'telescope.builtin\').live_grep()"\r', desc = 'Open nvim live grep', group = 'search' },
  { key = 'Space', mods = 'LEADER', action = act.QuickSelect, desc = 'Quick select (URLs, paths)', group = 'search' },

  -- Session management
  { key = 'S', mods = 'LEADER|SHIFT', action = actions.save_layout, desc = 'Save default layout', group = 'session' },
  { key = 'D', mods = 'LEADER|SHIFT', action = actions.restore_layout, desc = 'Restore default layout', group = 'session' },

  -- Other
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration, desc = 'Reload config', group = 'other' },
  { key = '\\', mods = 'LEADER|SHIFT', action = act.ShowDebugOverlay, desc = 'Debug overlay', group = 'other' },

  -- Quick scroll to bottom
  { key = 'PageDown', mods = 'CTRL', action = act.ScrollToBottom, desc = 'Scroll to bottom', group = 'scrollback' },
}

-- Copy mode keybindings (separate table, also with descriptions for help)
local copy_mode_defs = {
  { key = 'h', mods = 'NONE', desc = 'Move left' },
  { key = 'j', mods = 'NONE', desc = 'Move down' },
  { key = 'k', mods = 'NONE', desc = 'Move up' },
  { key = 'l', mods = 'NONE', desc = 'Move right' },
  { key = 'w', mods = 'NONE', desc = 'Forward word' },
  { key = 'b', mods = 'NONE', desc = 'Backward word' },
  { key = 'e', mods = 'NONE', desc = 'End of word' },
  { key = '0', mods = 'NONE', desc = 'Start of line' },
  { key = '$', mods = 'SHIFT', desc = 'End of line' },
  { key = 'g', mods = 'NONE', desc = 'Top of scrollback' },
  { key = 'G', mods = 'SHIFT', desc = 'Bottom of scrollback' },
  { key = 'Ctrl+u', mods = 'CTRL', desc = 'Page up' },
  { key = 'Ctrl+d', mods = 'CTRL', desc = 'Page down' },
  { key = 'v', mods = 'NONE', desc = 'Select characters' },
  { key = 'V', mods = 'SHIFT', desc = 'Select lines' },
  { key = 'y', mods = 'NONE', desc = 'Copy selection' },
  { key = 'Enter', mods = 'NONE', desc = 'Copy and exit' },
  { key = 'q/Esc', mods = 'NONE', desc = 'Exit copy mode' },
}

-- Helper: format keybind for display
local function format_keybind(mods, key)
  local parts = {}
  if mods:find('LEADER') then table.insert(parts, '<Leader>') end
  if mods:find('CTRL') and not mods:find('LEADER') then table.insert(parts, 'Ctrl') end
  if mods:find('ALT') then table.insert(parts, 'Alt') end
  if mods:find('SHIFT') then table.insert(parts, 'Shift') end
  table.insert(parts, key)
  return table.concat(parts, '+')
end

-- Build config.keys from definitions
config.keys = {
  -- Shift/Ctrl+Enter: send literal newline (useful for Claude Code multi-line input)
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\n' },
  { key = 'Enter', mods = 'CTRL', action = act.SendString '\n' },
}
for _, kb in ipairs(keybind_defs) do
  table.insert(config.keys, { key = kb.key, mods = kb.mods, action = kb.action })
end

-- Add help keybinding (Leader + h)
-- Opens full-screen help in new tab, q to close and return
table.insert(config.keys, {
  key = 'h',
  mods = 'LEADER',
  action = wezterm.action_callback(function(window, pane)
    -- ANSI colors matching theme
    local purple = '\x1b[38;2;157;78;221m'
    local cyan = '\x1b[38;2;78;205;196m'
    local yellow = '\x1b[38;2;255;230;109m'
    local dim = '\x1b[38;2;96;96;96m'
    local reset = '\x1b[0m'
    local bold = '\x1b[1m'

    local group_names = {
      nav = 'NAVIGATION',
      scrollback = 'SCROLLBACK',
      clipboard = 'CLIPBOARD',
      splits = 'SPLITS',
      tabs = 'TABS',
      panes = 'PANES',
      copymode = 'COPY MODE',
      search = 'SEARCH',
      session = 'SESSION',
      other = 'OTHER',
    }
    local group_order = { 'nav', 'scrollback', 'clipboard', 'splits', 'tabs', 'panes', 'copymode', 'search', 'session', 'other' }

    -- Group keybindings
    local grouped = {}
    for _, kb in ipairs(keybind_defs) do
      local g = kb.group or 'other'
      if not grouped[g] then grouped[g] = {} end
      table.insert(grouped[g], kb)
    end

    -- Build help text
    local lines = {}
    table.insert(lines, '')
    table.insert(lines, purple .. '  ╔══════════════════════════════════════════════════════╗' .. reset)
    table.insert(lines, purple .. '  ║' .. reset .. bold .. '           WezTerm Keybinding Reference               ' .. reset .. purple .. '║' .. reset)
    table.insert(lines, purple .. '  ║' .. reset .. dim .. '               Leader = Ctrl+Space                    ' .. reset .. purple .. '║' .. reset)
    table.insert(lines, purple .. '  ╚══════════════════════════════════════════════════════╝' .. reset)
    table.insert(lines, '')

    for _, group in ipairs(group_order) do
      if grouped[group] then
        table.insert(lines, '  ' .. cyan .. bold .. '┄┄┄ ' .. group_names[group] .. ' ┄┄┄' .. reset)
        for _, kb in ipairs(grouped[group]) do
          local keystr = format_keybind(kb.mods, kb.key)
          table.insert(lines, '    ' .. yellow .. string.format('%-18s', keystr) .. reset .. ' ' .. dim .. kb.desc .. reset)
        end
        table.insert(lines, '')
      end
    end

    -- Copy mode section
    table.insert(lines, '  ' .. cyan .. bold .. '┄┄┄ COPY MODE (after Leader+k) ┄┄┄' .. reset)
    for _, kb in ipairs(copy_mode_defs) do
      table.insert(lines, '    ' .. yellow .. string.format('%-18s', kb.key) .. reset .. ' ' .. dim .. kb.desc .. reset)
    end
    table.insert(lines, '')
    table.insert(lines, dim .. '  Press q to close' .. reset)
    table.insert(lines, '')

    -- Write to temp file (handle both native Linux and Windows/WSL)
    local help_text = table.concat(lines, '\n')
    local is_windows = wezterm.target_triple:find('windows')
    local temp_file, less_path

    if is_windows then
      -- Windows: write to Windows temp, convert to WSL path for less
      local temp_dir = os.getenv('TEMP') or os.getenv('TMP') or 'C:\\Temp'
      temp_file = temp_dir .. '\\wezterm_help.txt'
      less_path = temp_file:gsub('\\', '/'):gsub('^(%a):', function(drive)
        return '/mnt/' .. drive:lower()
      end)
    else
      -- Native Linux: write directly to /tmp
      temp_file = '/tmp/wezterm_help.txt'
      less_path = temp_file
    end

    local file = io.open(temp_file, 'w')
    if file then
      file:write(help_text)
      file:close()
    end

    -- Open in new tab with less, tab closes when less exits
    window:perform_action(act.SpawnCommandInNewTab {
      args = { 'less', '-R', less_path },
    }, pane)
  end),
})

-- =============================================================================
-- COPY MODE (vim keybindings for scrollback navigation)
-- Copying does NOT auto-close or snap to bottom - exit manually with q/Escape
-- =============================================================================

config.key_tables = {
  copy_mode = {
    -- Exit copy mode (snaps to bottom)
    { key = 'Escape', mods = 'NONE', action = act.Multiple {
      act.CopyMode 'Close',
      act.ScrollToBottom,
    }},
    { key = 'q', mods = 'NONE', action = act.Multiple {
      act.CopyMode 'Close',
      act.ScrollToBottom,
    }},

    -- Movement (vim-style)
    { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
    { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
    { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
    { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },

    -- Word movement
    { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
    { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
    { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },

    -- Line movement
    { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
    { key = '$', mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },
    { key = '^', mods = 'SHIFT', action = act.CopyMode 'MoveToStartOfLineContent' },

    -- Page/document movement
    { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
    { key = 'G', mods = 'SHIFT', action = act.CopyMode 'MoveToScrollbackBottom' },
    { key = 'u', mods = 'CTRL', action = act.CopyMode 'PageUp' },
    { key = 'd', mods = 'CTRL', action = act.CopyMode 'PageDown' },

    -- Selection
    { key = 'v', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Cell' } },
    { key = 'V', mods = 'SHIFT', action = act.CopyMode { SetSelectionMode = 'Line' } },
    { key = 'v', mods = 'CTRL', action = act.CopyMode { SetSelectionMode = 'Block' } },

    -- Copy and clear selection, but stay in copy mode at current position
    { key = 'y', mods = 'NONE', action = act.Multiple {
      act.CopyTo 'Clipboard',
      act.CopyMode 'ClearSelectionMode',
    }},

    -- Copy AND exit (snaps to bottom)
    { key = 'Enter', mods = 'NONE', action = act.Multiple {
      act.CopyTo 'Clipboard',
      act.CopyMode 'Close',
      act.ScrollToBottom,
    }},
  },
}

-- =============================================================================
-- MOUSE (right-click = context menu, no auto-copy, no middle-click)
-- =============================================================================

config.mouse_bindings = {
  -- Ctrl+Click opens links
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Disable middle-click paste (do nothing)
  {
    event = { Down = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = act.Nop,
  },
}

-- =============================================================================
-- SCROLLBACK & SCROLLBAR
-- =============================================================================

config.scrollback_lines = 10000
config.enable_scroll_bar = true

-- Don't scroll to bottom on input while in scrollback
config.scroll_to_bottom_on_input = false

-- =============================================================================
-- MISC SETTINGS
-- =============================================================================

config.automatically_reload_config = true
config.adjust_window_size_when_changing_font_size = false
config.window_close_confirmation = 'NeverPrompt'

-- Disable bell
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

-- =============================================================================
-- STATUS BAR (right side, like your tmux)
-- =============================================================================

-- Detect if we're on Windows (reading from WSL) or native Linux
local is_windows = wezterm.target_triple:find('windows') ~= nil

-- Background poller for sysinfo (8Hz refresh from daemon)
local function update_sysinfo()
  local cmd = is_windows
    and { 'wsl', '-e', 'cat', '/tmp/sysinfo' }
    or { 'cat', '/tmp/sysinfo' }
  local success, stdout = wezterm.run_child_process(cmd)
  if success and stdout then
    local content = stdout:gsub('%s+$', '')
    -- Split on double pipe: network || cpu/ram
    local sep_start, sep_end = content:find('||', 1, true)
    if sep_start then
      wezterm.GLOBAL.sysinfo_net = content:sub(1, sep_start - 1)
      wezterm.GLOBAL.sysinfo_cpuram = content:sub(sep_end + 1)
    else
      wezterm.GLOBAL.sysinfo_net = ''
      wezterm.GLOBAL.sysinfo_cpuram = content
    end
  end
  wezterm.time.call_after(0.125, update_sysinfo)  -- 8Hz
end

wezterm.time.call_after(0, update_sysinfo)

wezterm.on('update-right-status', function(window, pane)
  local date = wezterm.strftime '%I:%M%p %a %d-%b'
  local net = wezterm.GLOBAL.sysinfo_net or ''
  local cpuram = wezterm.GLOBAL.sysinfo_cpuram or ''

  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#808080' } },
    { Text = net .. '  ' },
    { Foreground = { Color = '#39ff14' } },
    { Text = cpuram .. '  ' },
    { Foreground = { Color = '#9d4edd' } },
    { Text = date .. ' ' },
  })
end)

-- =============================================================================
-- SESSION PERSISTENCE (resurrect plugin)
-- =============================================================================

-- Auto-save disabled (was causing scroll issues)
-- Uncomment to re-enable periodic session saving
-- resurrect.state_manager.periodic_save({
--   interval_seconds = 300,
--   save_workspaces = true,
--   save_windows = true,
--   save_tabs = true,
-- })

-- Restore last session on startup
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

return config
