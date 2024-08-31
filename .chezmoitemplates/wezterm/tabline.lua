local wezterm = require 'wezterm'

local M = {}

function M.tabline()
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
  tabline.setup({
    options = {
      icons_enabled = true,
      theme = 'Catppuccin Mocha',
      color_overrides = {},
      section_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      component_separators = {
        left = wezterm.nerdfonts.pl_left_soft_divider,
        right = wezterm.nerdfonts.pl_right_soft_divider,
      },
      tab_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = wezterm.nerdfonts.pl_right_hard_divider,
      },
    },
    sections = {
      tabline_a = { 'workspace' },
      tabline_b = {},
      tabline_c = {},
      tab_active = { 'tab_index', { 'process', padding = { left = 0, right = 1 } } },
      tab_inactive = { 'tab_index', { 'process', padding = { left = 0, right = 1 } } },
      tabline_x = {},
      tabline_y = { 'ram' },
      tabline_z = { 'cpu' },
    },
    extensions = { 'resurrect', 'smart_workspace_switcher' },
  })
end

function M.apply_to_config(config)
  config.use_fancy_tab_bar = false
  config.tab_bar_at_bottom = true
  config.hide_tab_bar_if_only_one_tab = true
  config.tab_max_width = 32
  config.unzoom_on_switch_pane = true
end

return M
