local wezterm = require 'wezterm' --[[@as Wezterm]]
local act = wezterm.action

local M = {}

M.mod = wezterm.target_triple:find 'windows' and 'SHIFT|CTRL' or 'SHIFT|SUPER'
M.super = wezterm.target_triple:find 'windows' and 'SHIFT|CTRL' or 'SUPER'
M.v = wezterm.target_triple:find 'windows' and 'CTRL' or 'SUPER'

M.smart_split = wezterm.action_callback(function(window, pane)
  local dim = pane:get_dimensions()
  ---@diagnostic disable-next-line: undefined-field
  if dim.pixel_height > dim.pixel_width then
    window:perform_action(act.SplitVertical { domain = 'CurrentPaneDomain' }, pane)
  else
    window:perform_action(act.SplitHorizontal { domain = 'CurrentPaneDomain' }, pane)
  end
end)

function M.apply_to_config(config, plugins)
  local resurrect = plugins.resurrect
  local workspace_switcher = plugins.workspace_switcher
  local smart_ssh = plugins.smart_ssh

  config.disable_default_key_bindings = true
  -- stylua: ignore
  config.keys = {
    -- Window
    { mods = 'ALT',        key = 'Enter', action = act.ToggleFullScreen },
    { mods = 'SUPER',      key = 'q',     action = act.QuitApplication },
    { mods = 'SHIFT|CTRL', key = 'q',     action = act.QuitApplication },
    { mods = 'CTRL',       key = '.',     action = act.SendKey{ mods = 'CTRL', key = '.' } },
    -- Sessions
    {
      mods = 'ALT',
      key = 'S',
      ---@diagnostic disable-next-line: unused-local
      action = wezterm.action_callback(function(win, pane)
        resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      end),
    },
    {
      mods = 'ALT',
      key = 's',
      action = resurrect.window_state.save_window_action(),
    },
    {
      mods = "ALT",
      key = "t",
      action = resurrect.tab_state.save_tab_action(),
    },
    {
      mods = 'ALT',
      key = 'o',
      action = wezterm.action_callback(function(win, pane)
        ---@diagnostic disable-next-line: unused-local
        resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
          local type = string.match(id, "^([^/]+)") -- match before '/'
          id = string.match(id, "([^/]+)$")         -- match after '/'
          id = string.match(id, "(.+)%..+$")        -- remove file extension
          local opts = {
            relative = true,
            restore_text = true,
            on_pane_restore = resurrect.tab_state.default_on_pane_restore,
          }
          if type == "workspace" then
            local state = resurrect.state_manager.load_state(id, "workspace")
            resurrect.workspace_state.restore_workspace(state, opts)
          elseif type == "window" then
            local state = resurrect.state_manager.load_state(id, "window")
            resurrect.window_state.restore_window(pane:window(), state, opts)
          elseif type == "tab" then
            local state = resurrect.state_manager.load_state(id, "tab")
            resurrect.tab_state.restore_tab(pane:tab(), state, opts)
          end
        end)
      end),
    },
    {
      mods = 'ALT',
      key = 'd',
      action = wezterm.action_callback(function(win, pane)
        ---@diagnostic disable-next-line: unused-local
        resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
            resurrect.state_manager.delete_state(id)
          end,
          {
            title = 'Delete State',
            fuzzy_description = 'Search State to Delete: ',
            is_fuzzy = true,
          })
      end),
    },
    -- Switch workspaces
    {
      mods = 'ALT',
      key = 'w',
      action = workspace_switcher.switch_workspace(),
    },
    -- Scrollback
    { mods = M.mod,   key = 'k',          action = act.ScrollByPage(-0.5) },
    { mods = M.mod,   key = 'j',          action = act.ScrollByPage(0.5) },
    -- Font Size
    { mods = M.super, key = '+',          action = act.IncreaseFontSize },
    { mods = M.super, key = '-',          action = act.DecreaseFontSize },
    { mods = M.super, key = '0',          action = act.ResetFontSize },
    -- Tabs
    { mods = M.mod,   key = 't',          action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = 'SUPER', key = 't',          action = act.SpawnTab 'CurrentPaneDomain' },
    { mods = M.mod,   key = 'w',          action = act.CloseCurrentTab { confirm = false } },
    { mods = 'SUPER', key = 'w',          action = act.CloseCurrentTab { confirm = false } },
    -- Move Tabs
    { mods = M.mod,   key = '>',          action = act.MoveTabRelative(1) },
    { mods = M.mod,   key = '<',          action = act.MoveTabRelative(-1) },
    -- Activate Tabs
    { mods = M.mod,   key = 'l',          action = act { ActivateTabRelative = 1 } },
    { mods = M.mod,   key = 'h',          action = act { ActivateTabRelative = -1 } },
    -- Splits
    { mods = M.mod,   key = 'Enter',      action = M.smart_split },
    { mods = M.mod,   key = '|',          action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { mods = M.mod,   key = '_',          action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    -- Activate Panes
    -- NOTE: 'CTRL' + 'h/j/k/l' is setup by smart_splits plugin
    { mods = 'ALT',   key = 'Backspace',  action = act.CloseCurrentPane { confirm = false } },
    { mods = 'CTRL',  key = 'Backspace',  action = act.CloseCurrentPane { confirm = false } },
    { mods = M.mod,   key = 'r',          action = wezterm.action.RotatePanes 'Clockwise' },
    -- Resize Panes
    -- NOTE: 'ALT' + 'h/j/k/l' is setup by smart_splits plugin
    { mods = 'ALT',   key = 'LeftArrow',  action = act.AdjustPaneSize { 'Left', 3 } },
    { mods = 'ALT',   key = 'DownArrow',  action = act.AdjustPaneSize { 'Down', 3 } },
    { mods = 'ALT',   key = 'UpArrow',    action = act.AdjustPaneSize { 'Up', 3 } },
    { mods = 'ALT',   key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 3 } },
    { mods = 'ALT',   key = 'm',          action = act.TogglePaneZoomState },
    -- Clipboard
    { mods = M.v,     key = 'c',          action = act.CopyTo 'Clipboard' },
    { mods = M.mod,   key = ':',          action = act.QuickSelect },
    { mods = M.mod,   key = 'x',          action = act.ActivateCopyMode },
    { mods = M.mod,   key = 'f',          action = act.Search 'CurrentSelectionOrEmptyString' },
    -- Interferes with visual block mode in nvim
    -- { mods = M.v, key = 'v', action = act.PasteFrom 'Clipboard' },
    { mods = M.super, key = 'v',          action = act.PasteFrom 'Clipboard' },
    { mods = M.mod,   key = 'p',          action = act.ActivateCommandPalette },
    { mods = M.mod,   key = 'd',          action = act.ShowDebugOverlay },
    -- Domains
    { mods = 'ALT|SHIFT', key = 'D',      action = smart_ssh.tab() },
  }

  -- Select tab with 'CTRL' + tab number
  for i = 1, 9 do
    table.insert(config.keys, { mods = 'CTRL', key = tostring(i), action = act { ActivateTab = i - 1 } })
  end
end

return M
