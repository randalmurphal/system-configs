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

-- Default to WSL
config.default_domain = 'WSL:Ubuntu-24.04'

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

-- Inactive panes darker, no color change
config.inactive_pane_hsb = {
  saturation = 1.0,  -- no change to colors
  brightness = 0.6,  -- 40% darker
}

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
-- KEYBINDINGS
-- =============================================================================

config.keys = {
  -- =========================================================================
  -- DIRECT NAVIGATION (no leader, these are your most frequent)
  -- =========================================================================

  -- Alt+hjkl = navigate panes
  { key = 'h', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

  -- Alt+Shift+h/l = previous/next tab
  { key = 'h', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'l', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(1) },

  -- =========================================================================
  -- COPY/PASTE (explicit only)
  -- =========================================================================

  -- Ctrl+Shift+C = copy selection to clipboard
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },

  -- Ctrl+Shift+V = paste from clipboard
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- =========================================================================
  -- LEADER-BASED (less frequent operations)
  -- =========================================================================

  -- Splits (like your tmux)
  -- Leader + v = split right (horizontal)
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  -- Leader + V = split down (vertical)
  { key = 'V', mods = 'LEADER|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Close
  -- Leader + x = close current pane
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  -- Leader + X = close current tab
  { key = 'X', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true } },

  -- Tabs
  -- Leader + n = new tab
  { key = 'n', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Leader + number = switch to tab
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },

  -- Pane operations
  -- Leader + z = zoom/unzoom pane (fullscreen current pane)
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Leader + a = break current pane to new tab and switch to it
  { key = 'a', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)
    local tab, _ = pane:move_to_new_tab()
    tab:activate()
  end) },

  -- Leader + b = bring a pane from another tab into this one
  { key = 'b', mods = 'LEADER', action = wezterm.action_callback(function(window, pane)
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
  end) },

  -- Leader + p = swap current pane with another (picker)
  { key = 'p', mods = 'LEADER', action = act.PaneSelect {
    mode = 'SwapWithActive',
    alphabet = '1234567890',
  } },

  -- Leader + { = rotate panes counter-clockwise
  { key = '{', mods = 'LEADER|SHIFT', action = act.RotatePanes 'CounterClockwise' },

  -- Leader + } = rotate panes clockwise
  { key = '}', mods = 'LEADER|SHIFT', action = act.RotatePanes 'Clockwise' },

  -- Copy mode (vim navigation in scrollback)
  -- Leader + k = enter copy mode
  { key = 'k', mods = 'LEADER', action = act.ActivateCopyMode },

  -- Config
  -- Leader + r = reload config
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },

  -- Search
  -- Leader + f = search in scrollback
  { key = 'f', mods = 'LEADER', action = act.Search 'CurrentSelectionOrEmptyString' },

  -- Leader + g = open nvim with telescope live_grep (like space+s+g in nvim)
  { key = 'g', mods = 'LEADER', action = act.SendString 'nvim -c "lua require(\'telescope.builtin\').live_grep()"\r' },

  -- Quick select (URLs, file paths, etc - semantic selection!)
  -- Leader + Space = quick select mode
  { key = 'Space', mods = 'LEADER', action = act.QuickSelect },

  -- Debug (useful for troubleshooting)
  { key = '?', mods = 'LEADER|SHIFT', action = act.ShowDebugOverlay },

  -- =========================================================================
  -- SESSION MANAGEMENT (resurrect plugin)
  -- =========================================================================

  -- Leader + s = save current state
  { key = 's', mods = 'LEADER', action = wezterm.action_callback(function(win, pane)
    local state = resurrect.workspace_state.get_workspace_state()
    resurrect.state_manager.save_state(state)
    wezterm.log_info("Session saved")
  end) },

  -- Leader + R = restore (fuzzy finder to pick from saved states)
  { key = 'R', mods = 'LEADER|SHIFT', action = wezterm.action_callback(function(win, pane)
    resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
      local state = resurrect.state_manager.load_state(id, "workspace")
      resurrect.workspace_state.restore_workspace(state, {
        window = win,
        relative = true,
        restore_text = true,
      })
    end)
  end) },
}

-- =============================================================================
-- COPY MODE (vim keybindings for scrollback navigation)
-- Copying does NOT auto-close or snap to bottom - exit manually with q/Escape
-- =============================================================================

config.key_tables = {
  copy_mode = {
    -- Exit copy mode (removes highlighting, snaps to command line)
    { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
    { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },

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
    { key = 'u', mods = 'CTRL|SHIFT', action = act.CopyMode 'PageUp' },
    { key = 'd', mods = 'CTRL|SHIFT', action = act.CopyMode 'PageDown' },

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

-- Background poller for sysinfo (8Hz refresh from daemon)
local function update_sysinfo()
  local success, stdout = wezterm.run_child_process({
    'wsl', '-e', 'cat', '/tmp/sysinfo'
  })
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

-- Auto-save every 5 minutes
resurrect.state_manager.periodic_save({
  interval_seconds = 300,
  save_workspaces = true,
  save_windows = true,
  save_tabs = true,
})

-- Restore last session on startup
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

return config
