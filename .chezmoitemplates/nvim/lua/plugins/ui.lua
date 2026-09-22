return {
  ---@module 'catppuccin'
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    ---@type CatppuccinOptions
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      float = { transparent = true, solid = false },
      auto_integrations = true,
      integrations = {
        navic = { enabled = true, custom_bg = 'NONE' },
        snacks = { enabled = true, indent_scope_color = 'lavender' },
      },
      highlight_overrides = {
        mocha = function(mocha)
          return {
            CursorLine = { bg = 'NONE' },
            CursorLineNr = { fg = mocha.yellow },
            LineNrAbove = { fg = mocha.subtext0 },
            LineNrBelow = { fg = mocha.subtext0 },
            LineNrInactive = { fg = mocha.overlay0 },
          }
        end,
      },
    },
  },
  {
    'brenoprata10/nvim-highlight-colors',
    lazy = true,
    event = 'BufReadPost',
    opts = { enable_tailwind = true },
  },
  ---@module 'which-key'
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    ---@type wk.Config|{}
    opts = {
      preset = 'helix',
      delay = 600,
    },
    config = function(_, opts)
      local wk = require 'which-key'
      -- stylua: ignore
      wk.add {
        { '<leader>b', group = '[B]uffer', mode = { 'n', 'x' }, icon = { icon = '󰈔 ', color = 'cyan' } },
        { '<leader>c', group = '[C]ode',   mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
        { '<leader>d', group = '[D]ocument',                    icon = { icon = '󰈙', color = 'green' } },
        { '<leader>g', group = '[G]it',                         icon = { icon = '', color = 'green' } },
        { '<leader>r', group = '[R]ename',                      icon = { icon = '󰑕', color = 'orange' } },
        { '<leader>s', group = '[S]earch',                      icon = { icon = '', color = 'green' } },
        { '<leader>t', group = '[T]oggle/[T]est',               icon = { icon = '', color = 'orange' } },
        { '<leader>u', group = '[U]I Toggles',                  icon = { icon = ' ', color = 'yellow' } },
        { '<leader>m', desc = '[M]essages',                     icon = { icon = '󰍩 ', color = 'blue' } },
      }
      wk.setup(opts)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
