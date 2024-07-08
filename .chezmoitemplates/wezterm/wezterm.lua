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

local wezterm = require 'wezterm'
local config = wezterm.config_builder()
wezterm.log_info 'reloading'

-- Modules
require('tabs').setup(config)
require('mouse').setup(config)
require('links').setup(config)
require('keys').setup(config)
local session_manager = require 'sessions'
local smart_splits = wezterm.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
local workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'

-- Graphics config
config.front_end = 'WebGpu'
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

--  Colour scheme and UI
config.adjust_window_size_when_changing_font_size = false
config.bold_brightens_ansi_colors = true
config.color_scheme = 'Catppuccin Mocha'
local modal_bg_color = 'rgba(26, 27, 38, 0.92)'
local modal_fg_color = '#a9b1d6'
config.command_palette_bg_color = modal_bg_color
config.command_palette_fg_color = modal_fg_color
config.char_select_bg_color = modal_bg_color
config.char_select_fg_color = modal_fg_color
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
config.window_background_opacity = 0.92
config.window_close_confirmation = 'AlwaysPrompt'
config.window_padding = { left = 6, right = 6, top = 6, bottom = 0 }

-- Windows, MacOS and Linux
local primary_font = 'IosevkaTerm Nerd Font'
if wezterm.target_triple:find 'windows' then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.window_decorations = 'RESIZE'
  config.font_size = 12
  config.command_palette_font_size = 12
  config.char_select_font_size = 12
elseif wezterm.target_triple:find 'linux' then
  config.term = 'wezterm'
  config.window_decorations = 'NONE'
  config.enable_wayland = true
  config.webgpu_power_preference = 'HighPerformance'
  config.font_size = 14
  config.command_palette_font_size = 14
  config.char_select_font_size = 14
  primary_font = 'Iosevka Term'
else
  config.default_prog = { '/opt/homebrew/bin/zsh', '-l' }
  config.window_decorations = 'RESIZE'
  config.font_size = 16
  config.command_palette_font_size = 16
  config.char_select_font_size = 16
end

-- Fonts
config.font = wezterm.font_with_fallback {
  { family = primary_font, weight = 'Regular' },
  { family = 'MesloLGS NF', weight = 'Regular' },
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

-- SSH domains
config.ssh_domains = wezterm.default_ssh_domains()

-- Sessions
wezterm.on('save_session', function(window)
  session_manager.save_state(window)
end)
wezterm.on('restore_session', function(window)
  session_manager.restore_state(window)
end)

--Workspaces
workspace_switcher.apply_to_config(config)
---@diagnostic disable-next-line: unused-local
wezterm.on('augment-command-palette', function(window, pane)
  return {
    {
      brief = 'Window | Workspace: Rename Workspace',
      icon = 'md_briefcase_edit',

      action = wezterm.action.PromptInputLine {
        description = 'Enter new name for wokspace',
        ---@diagnostic disable-next-line: unused-local, redefined-local
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
          end
        end),
      },
    },
  }
end)

-- Smart Splits
smart_splits.apply_to_config(config)

return config
