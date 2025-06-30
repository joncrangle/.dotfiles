-- NOTE:
-- My Wezterm config file
-- ██╗    ██╗███████╗███████╗████████╗███████╗██████╗ ███╗   ███╗
-- ██║    ██║██╔════╝╚══███╔╝╚══██╔══╝██╔════╝██╔══██╗████╗ ████║
-- ██║ █╗ ██║█████╗    ███╔╝    ██║   █████╗  ██████╔╝██╔████╔██║
-- ██║███╗██║██╔══╝   ███╔╝     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║
-- ╚███╔███╔╝███████╗███████╗   ██║   ███████╗██║  ██║██║ ╚═╝ ██║
--  ╚══╝╚══╝ ╚══════╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
-- A GPU-accelerated cross-platform terminal emulator
-- https://wezfurlong.org/wezterm/

local wezterm = require 'wezterm' --[[@as Wezterm]]
pcall(wezterm.plugin.update_all)
local config = wezterm.config_builder() ---@class Config
wezterm.log_info 'reloading'

-- Modules
if not wezterm.target_triple:find 'windows' then
  require('podman').apply_to_config(config)
end
require('keys').apply_to_config(config)
require('links').apply_to_config(config)
require('mouse').apply_to_config(config)
require('tabline').apply_to_config(config)
require('tabline').tabline()

-- Graphics config
config.front_end = 'WebGpu'
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'
config.enable_kitty_graphics = true
config.max_fps = 120

--  Colour scheme and UI
config.adjust_window_size_when_changing_font_size = false
config.bold_brightens_ansi_colors = true
local scheme = wezterm.get_builtin_color_schemes()['Catppuccin Mocha']
scheme.tab_bar.background = 'rgba(30, 30, 46, 0.8)'
config.color_scheme = 'Catppuccin Mocha'
local modal_bg_color = 'rgba(26, 27, 38, 0.92)'
local modal_fg_color = '#a9b1d6'
config.command_palette_bg_color = modal_bg_color
config.command_palette_fg_color = modal_fg_color
config.char_select_bg_color = modal_bg_color
config.char_select_fg_color = modal_fg_color
config.color_schemes = {
  ['Catppuccin Mocha'] = scheme,
}
config.cursor_thickness = 2
config.default_cursor_style = 'BlinkingBar'
config.force_reverse_video_cursor = true
config.hide_tab_bar_if_only_one_tab = true
config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.4,
}
config.scrollback_lines = 5000
config.underline_thickness = 3
config.underline_position = -6
config.warn_about_missing_glyphs = false
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = { left = 2, right = 0, top = 3, bottom = 0 }

local font_size
local primary_font = 'Berkeley Mono'
local secondary_font = 'IosevkaTerm Nerd Font'
-- Windows, MacOS and Linux
if wezterm.target_triple:find 'windows' then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.window_background_opacity = 0
  config.window_decorations = 'RESIZE'
  config.win32_system_backdrop = 'Mica'
  font_size = 12
elseif wezterm.target_triple:find 'linux' then
  config.window_decorations = 'NONE'
  config.enable_wayland = true
  config.webgpu_power_preference = 'LowPower'
  config.window_background_opacity = 0.8
  font_size = 14
  secondary_font = 'Iosevka Term'
else
  config.default_prog = { '/opt/homebrew/bin/zsh', '-l' }
  config.macos_window_background_blur = 20
  config.window_background_opacity = 0.6
  config.window_decorations = 'RESIZE'
  font_size = 16
end

config.font_size = font_size
config.command_palette_font_size = font_size
config.char_select_font_size = font_size

-- Fonts
config.font = wezterm.font_with_fallback {
  { family = primary_font, weight = 'Regular' },
  { family = secondary_font, weight = 'Regular' },
  { family = 'Symbols Nerd Font Mono', weight = 'Regular' },
}
config.font_rules = {
  {
    intensity = 'Bold',
    italic = true,
    font = wezterm.font { family = 'Maple Mono', weight = 'Bold', style = 'Italic' },
  },
  {
    italic = true,
    intensity = 'Half',
    font = wezterm.font { family = 'Maple Mono', weight = 'DemiBold', style = 'Italic' },
  },
  {
    italic = true,
    intensity = 'Normal',
    font = wezterm.font { family = 'Maple Mono', style = 'Italic' },
  },
}
config.harfbuzz_features = { 'ss06' }

-- Sessions
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
local separator = wezterm.target_triple:find 'windows' and '\\' or '/'
local encryption_method = wezterm.target_triple:find 'darwin' and '/opt/homebrew/bin/age' or 'age'
resurrect.state_manager.set_encryption {
  enable = true,
  method = encryption_method,
  private_key = wezterm.home_dir .. separator .. '.config' .. separator .. 'key.txt',
  public_key = '{{- .chezmoi.config.age.recipient -}}',
}
resurrect.state_manager.periodic_save()
resurrect.state_manager.set_max_nlines(1000)

--Workspaces
local workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'
local workspace_state = resurrect.workspace_state
workspace_switcher.workspace_formatter = function(label)
  return wezterm.format {
    { Attribute = { Italic = true } },
    { Foreground = { Color = scheme.ansi[3] } },
    { Background = { Color = scheme.background } },
    { Text = '󱂬 : ' .. label },
  }
end

local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

local resurrect_event_listeners = {
  'resurrect.error',
  'resurrect.state_manager.save_state.finished',
}
local is_periodic_save = false
wezterm.on('resurrect.state_manager.periodic_save', function()
  is_periodic_save = true
end)
for _, event in ipairs(resurrect_event_listeners) do
  wezterm.on(event, function(...)
    if event == 'resurrect.save_state.finished' and is_periodic_save then
      is_periodic_save = false
      return
    end
    local args = { ... }
    local msg = event
    for _, v in ipairs(args) do
      msg = msg .. ' ' .. tostring(v)
    end
    wezterm.gui.gui_windows()[1]:toast_notification('Wezterm - resurrect', msg, nil, 4000)
  end)
end

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, path, label)
  window:gui_window():set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = scheme.ansi[5] } },
    { Text = basename(path) .. '  ' },
  })
  workspace_state.restore_workspace(resurrect.state_manager.load_state(label, 'workspace'), {
    window = window,
    relative = true,
    restore_text = true,
    on_pane_restore = resurrect.tab_state.default_on_pane_restore,
  })
end)

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, path, label)
  window:gui_window():set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = scheme.ansi[5] } },
    { Text = basename(path) .. '  ' },
  })
end)

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, path, label)
  resurrect.state_manager.save_state(workspace_state.get_workspace_state())
end)

-- Domains
local domains = wezterm.plugin.require 'https://github.com/DavidRR-F/quick_domains.wezterm'
domains.formatter = function(icon, name)
  return wezterm.format {
    { Foreground = { Color = scheme.ansi[5] } },
    { Background = { Color = scheme.background } },
    { Text = icon .. ' ' .. name },
  }
end

---@diagnostic disable-next-line: unused-local
wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Window | Workspace: Switch Workspace',
      icon = 'md_briefcase_arrow_up_down',
      action = workspace_switcher.switch_workspace(),
    },
    {
      brief = 'Window | Workspace: Rename Workspace',
      icon = 'md_briefcase_edit',
      action = wezterm.action.PromptInputLine {
        description = 'Enter new name for workspace',
        ---@diagnostic disable-next-line: unused-local, redefined-local
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      },
    },
    {
      brief = 'Window | Workspace: Rename Window',
      icon = 'cod_window',
      action = wezterm.action.PromptInputLine {
        description = 'Enter new name for window',
        ---@diagnostic disable-next-line: unused-local, redefined-local
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:mux_window():set_title(line)
          end
        end),
      },
    },
  }
end)

-- Smart Splits
local smart_splits = wezterm.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
smart_splits.apply_to_config(config)

return config
