return {
  {
    'nvim-lualine/lualine.nvim',
    lazy = true,
    event = 'VeryLazy',
    dependencies = { 'echasnovski/mini.icons' },
    opts = {
      options = {
        theme = 'catppuccin',
        extensions = {
          'lazy',
          'mason',
          'neo-tree',
          'nvim-dap-ui',
          'oil',
          'quickfix',
          'trouble',
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
