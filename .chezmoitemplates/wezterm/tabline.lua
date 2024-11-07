local wezterm = require 'wezterm' --[[@as Wezterm]]
local colors = wezterm.get_builtin_color_schemes()['Catppuccin Mocha']

local M = {}

local process_to_icon = {
  ['nvim'] = { color = { fg = colors.compose_cursor } },
  ['ollama'] = { wezterm.nerdfonts.cod_code, color = { fg = colors.cursor_bg } },
}

function M.tabline()
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'

  tabline.setup({
    options = {
      icons_enabled = true,
      theme = 'Catppuccin Mocha',
      color_overrides = {
        tab = {
          active = { fg = colors.tab_bar.active_tab.bg_color, bg = colors.tab_bar.new_tab.bg_color },
        },
      },
      section_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      component_separators = {
        left = wezterm.nerdfonts.pl_left_soft_divider,
        right = wezterm.nerdfonts.pl_right_soft_divider,
      },
      tab_separators = {
        left = wezterm.nerdfonts.ple_right_half_circle_thick,
        right = wezterm.nerdfonts.ple_left_half_circle_thick,
      },
    },
    sections = {
      tabline_a = { 'workspace' },
      tabline_b = { not wezterm.target_triple:find 'windows' and 'window' },
      tabline_c = { '' },
      tab_active = {
        { Text = wezterm.nerdfonts.cod_triangle_right .. ' ' },
        { 'zoomed',                                          padding = 0 },
        { 'tab_index',                                       padding = { left = 0, right = 1 } },
        {
          'process',
          padding = { left = 0, right = 1 },
          icons_only = true,
          process_to_icon = process_to_icon,
        },
      },
      tab_inactive = {
        { Text = wezterm.nerdfonts.cod_chevron_right .. ' ' },
        { 'zoomed',                                         padding = 0 },
        { 'tab_index',                                      padding = { left = 0, right = 1 } },
        {
          'process',
          padding = { left = 0, right = 1 },
          icons_only = true,
          process_to_icon = process_to_icon,
        },
      },
      tabline_x = { ' ' },
      tabline_y = {},
      tabline_z = { { 'datetime', style = '%I:%M %p' } },
    },
    extensions = { 'resurrect', 'smart_workspace_switcher', 'quick_domains' },
  })
end

function M.apply_to_config(config)
  config.hide_tab_bar_if_only_one_tab = true
  config.show_new_tab_button_in_tab_bar = false
  config.tab_bar_at_bottom = true
  config.tab_max_width = 32
  config.unzoom_on_switch_pane = true
  config.use_fancy_tab_bar = false
end

return M
