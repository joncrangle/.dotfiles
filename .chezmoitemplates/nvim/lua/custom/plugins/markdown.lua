return {
  {
    'OXY2DEV/markview.nvim',
    dependencies = {
      'echasnovski/mini.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    enabled = false,
    ft = { 'markdown' },
    opts = {},
    keys = {
      {
        '<leader>tm',
        '<cmd>Markview<cr>',
        ft = 'markdown',
        desc = '[T]oggle [M]arkview',
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    ft = { 'markdown' },
    opts = {},
    keys = {
      {
        '<leader>tm',
        '<cmd>RenderMarkdown toggle<cr>',
        ft = 'markdown',
        desc = '[T]oggle [M]arkdown',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
