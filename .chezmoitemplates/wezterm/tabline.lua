local wezterm = require 'wezterm'

local M = {}

local icons = {
  ['C:\\WINDOWS\\system32\\cmd.exe'] = wezterm.nerdfonts.md_console_line,
  ['Topgrade'] = wezterm.nerdfonts.md_rocket_launch,
  ['bash'] = wezterm.nerdfonts.cod_terminal_bash,
  ['btm'] = wezterm.nerdfonts.mdi_chart_donut_variant,
  ['btop'] = wezterm.nerdfonts.md_chart_areaspline,
  ['btop4win++'] = wezterm.nerdfonts.md_chart_areaspline,
  ['cargo'] = wezterm.nerdfonts.dev_rust,
  ['curl'] = wezterm.nerdfonts.mdi_flattr,
  ['docker'] = wezterm.nerdfonts.linux_docker,
  ['docker-compose'] = wezterm.nerdfonts.linux_docker,
  ['fish'] = wezterm.nerdfonts.md_fish,
  ['gh'] = wezterm.nerdfonts.dev_github_badge,
  ['git'] = wezterm.nerdfonts.dev_git,
  ['go'] = wezterm.nerdfonts.seti_go,
  ['htop'] = wezterm.nerdfonts.md_chart_areaspline,
  ['kubectl'] = wezterm.nerdfonts.linux_docker,
  ['kuberlr'] = wezterm.nerdfonts.linux_docker,
  ['lazydocker'] = wezterm.nerdfonts.linux_docker,
  ['lazygit'] = wezterm.nerdfonts.cod_github,
  ['lua'] = wezterm.nerdfonts.seti_lua,
  ['make'] = wezterm.nerdfonts.seti_makefile,
  ['node'] = wezterm.nerdfonts.mdi_hexagon,
  ['nvim'] = wezterm.nerdfonts.custom_neovim,
  ['pacman'] = wezterm.nerdfonts.md_pac_man,
  ['paru'] = wezterm.nerdfonts.md_pac_man,
  ['powershell.exe'] = wezterm.nerdfonts.md_console,
  ['psql'] = wezterm.nerdfonts.dev_postgresql,
  ['pwsh.exe'] = wezterm.nerdfonts.md_console,
  ['ruby'] = wezterm.nerdfonts.cod_ruby,
  ['sudo'] = wezterm.nerdfonts.fa_hashtag,
  ['vim'] = wezterm.nerdfonts.dev_vim,
  ['wget'] = wezterm.nerdfonts.mdi_arrow_down_box,
  ['yay'] = wezterm.nerdfonts.md_pac_man,
  ['zsh'] = wezterm.nerdfonts.dev_terminal,
}

function M.tabline()
  local tabline = wezterm.plugin.require 'https://github.com/michaelbrusegard/tabline.wez'
  local colors = wezterm.get_builtin_color_schemes()['Catppuccin Mocha']

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
        right = '',
      },
      component_separators = {
        left = '',
        right = '',
      },
      tab_separators = {
        left = wezterm.nerdfonts.pl_left_hard_divider,
        right = '',
      },
    },
    sections = {
      tabline_a = { 'workspace' },
      tabline_b = { 'window' },
      tabline_c = {},
      tab_active = {
        {
          'tab_index',
          fmt = function(str) return wezterm.nerdfonts.cod_triangle_right .. ' ' .. str end
        },
        {
          'process',
          padding = { left = 0, right = 1 },
          fmt = function(str) return icons[str] or wezterm.nerdfonts.md_application end
        }
      },
      tab_inactive = {
        {
          'tab_index',
          fmt = function(str) return wezterm.nerdfonts.cod_chevron_right .. ' ' .. str end
        },
        {
          'process',
          padding = { left = 0, right = 1 },
          fmt = function(str) return icons[str] or wezterm.nerdfonts.md_application end
        }
      },
      tabline_x = {},
      tabline_y = {},
      tabline_z = {},
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
