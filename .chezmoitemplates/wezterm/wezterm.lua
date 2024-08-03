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
wezterm.plugin.update_all()
local config = wezterm.config_builder()
wezterm.log_info 'reloading'

-- Modules
require('tabs').setup(config)
require('mouse').setup(config)
require('links').setup(config)
require('keys').setup(config)

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
config.warn_about_missing_glyphs = false
config.window_background_opacity = 0.8
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
  { family = primary_font,             weight = 'Regular' },
  { family = 'MesloLGS NF',            weight = 'Regular' },
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
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
resurrect.set_encryption {
  enable = true,
  private_key = wezterm.home_dir .. '/.config/key.txt',
  public_key = 'age1jgcaj9yy8nldpp2969kgxf97re59v6ydnk5ctz02z8anc4522pxswpcqf2',
}
resurrect.periodic_save()

--Workspaces
local colors = wezterm.get_builtin_color_schemes()['Catppuccin Mocha']
local workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'
local workspace_state = resurrect.workspace_state
workspace_switcher.apply_to_config(config)
workspace_switcher.set_workspace_formatter(function(label)
  return wezterm.format {
    { Attribute = { Italic = true } },
    { Foreground = { Color = colors.ansi[3] } },
    { Background = { Color = colors.background } },
    { Text = '󱂬 : ' .. label },
  }
end)

local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, path, label)
  window:gui_window():set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = colors.ansi[5] } },
    { Text = basename(path) .. '  ' },
  })
  workspace_state.restore_workspace(resurrect.load_state(label, 'workspace'), {
    window = window,
    relative = true,
    restore_text = true,
    on_pane_restore = (require(resurrect.plugin.resurrect.tab_state)).default_on_pane_restore,
  })
end)

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, path, label)
  window:gui_window():set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = colors.ansi[5] } },
    { Text = basename(path) .. '  ' },
  })
end)

---@diagnostic disable-next-line: unused-local
wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, path, label)
  resurrect.save_state(workspace_state.get_workspace_state())
end)

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
            resurrect.save_state(workspace_state.get_workspace_state())
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
