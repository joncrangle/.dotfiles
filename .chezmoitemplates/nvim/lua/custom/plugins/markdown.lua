return {
  {
    'OXY2DEV/markview.nvim',
    dependencies = {
      'echasnovski/mini.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    enabled = false,
    ft = { 'markdown' },
    opts = true,
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
    'MeanderingProgrammer/markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    ft = { 'markdown' },
    opts = true,
    keys = {
      {
        '<leader>tm',
        '<cmd>RenderMarkdownToggle<cr>',
        ft = 'markdown',
        desc = '[T]oggle [M]arkdown',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
