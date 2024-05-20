return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        tailwindcss = {},
      },
    },
  },
  {
    'roobert/tailwindcss-colorizer-cmp.nvim',
    lazy = true,
    event = 'InsertEnter',
    opts = {
      color_square_width = 2,
    },
  },
  {
    'brenoprata10/nvim-highlight-colors',
    lazy = true,
    event = 'BufReadPost',
    opts = {
      enable_tailwind = true,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
