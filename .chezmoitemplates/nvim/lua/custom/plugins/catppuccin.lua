return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = true,
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      integrations = {
        mini = {
          enabled = true,
          indentscope_color = 'lavender',
        },
      },
      highlight_overrides = {
        mocha = function(mocha)
          return {
            LineNrAbove = { fg = mocha.overlay1 },
            LineNrBelow = { fg = mocha.overlay1 },
            CursorLineNr = { fg = mocha.rosewater },
          }
        end,
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
