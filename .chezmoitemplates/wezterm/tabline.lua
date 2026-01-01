local wezterm = require 'wezterm' --[[@as Wezterm]]
local colors = wezterm.color.get_builtin_schemes()['Catppuccin Mocha']

local M = {}

local process_to_icon = {
  ['default'] = { wezterm.nerdfonts.md_application, color = { fg = colors.cursor_bg } },
  ['lazysql'] = { wezterm.nerdfonts.cod_database, color = { fg = colors.ansi[4] } },
  ['nvim'] = { color = { fg = colors.compose_cursor } },
  ['ollama'] = { wezterm.nerdfonts.cod_code, color = { fg = colors.cursor_bg } },
  ['ssh'] = { wezterm.nerdfonts.md_ssh, color = { fg = colors.ansi[3] } },
}

function M.tabline()
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
  local transparent = 'rgba(0,0,0,0)'

  ---@diagnostic disable-next-line: undefined-field
  tabline.setup {
    options = {
      icons_enabled = true,
      theme = 'Catppuccin Mocha',
      theme_overrides = {
        tab = {
          active = { fg = colors.ansi[6], bg = colors.tab_bar.inactive_tab.bg_color },
          inactive = { fg = colors.compose_cursor, bg = colors.tab_bar.inactive_tab.bg_color },
        },
        normal_mode = { x = { bg = transparent } },
        copy_mode = { x = { bg = transparent } },
        search_mode = { x = { bg = transparent } },
        window_mode = { x = { bg = transparent } },
      },
      section_separators = '',
      component_separators = '',
      tab_separators = '',
    },
    sections = {
      tabline_a = { 'workspace' },
      tabline_b = { not wezterm.target_triple:find 'windows' and 'window' },
      tabline_c = { '' },
      tab_active = {
        { Text = wezterm.nerdfonts.cod_triangle_right .. ' ' },
        { 'zoomed', padding = 0 },
        { 'tab_index', padding = { left = 0, right = 1 } },
        {
          'process',
          padding = { left = 0, right = 1 },
          icons_only = true,
          process_to_icon = process_to_icon,
        },
      },
      tab_inactive = {
        { Text = wezterm.nerdfonts.cod_chevron_right .. ' ' },
        { 'zoomed', padding = 0 },
        { 'tab_index', padding = { left = 0, right = 1 } },
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
  }
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
