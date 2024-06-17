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
local smart_splits = wezterm.plugin.require 'https://github.com/mrjones2014/smart-splits.nvim'
local config = wezterm.config_builder()
wezterm.log_info 'reloading'

-- Modules
require('tabs').setup(config)
require('mouse').setup(config)
require('links').setup(config)
require('keys').setup(config)
require('domains').setup(config)

-- Graphics config
config.front_end = 'WebGpu'
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

--  Colour scheme and UI
config.adjust_window_size_when_changing_font_size = false
config.color_scheme = 'Catppuccin Mocha'
config.command_palette_bg_color = 'rgba(26, 27, 38, 0.92)'
config.command_palette_fg_color = '#a9b1d6'
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
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = { left = 6, right = 6, top = 6, bottom = 0 }

-- Windows and MacOS
if wezterm.target_triple:find 'windows' then
  config.default_prog = { 'pwsh.exe', '-NoLogo' }
  config.window_decorations = 'RESIZE|TITLE'
  config.font_size = 12
  wezterm.on('gui-startup', function(cmd)
    local screen = wezterm.gui.screens().active
    ---@diagnostic disable-next-line: unused-local
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    local gui = window:gui_window()
    local width = 0.7 * screen.width
    local height = 0.7 * screen.height
    gui:set_inner_size(width, height)
    gui:set_position((screen.width - width) / 2, (screen.height - height) / 2)
  end)
else
  config.default_prog = { '/opt/homebrew/bin/zsh', '-l' }
  config.window_decorations = 'RESIZE'
  config.font_size = 16
end

-- Sessions
local session_manager = require 'sessions'
wezterm.on('save_session', function(window)
  session_manager.save_state(window)
end)
wezterm.on('restore_session', function(window)
  session_manager.restore_state(window)
end)

-- Fonts
config.font = wezterm.font_with_fallback {
  { family = 'IosevkaTerm Nerd Font', weight = 'Regular' },
  { family = 'MesloLGS NF', weight = 'Regular' },
}
config.bold_brightens_ansi_colors = true
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

smart_splits.apply_to_config(config)

return config
