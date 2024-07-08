return {
  'OXY2DEV/markview.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  ft = { 'markdown' },
  opts = true,
  keys = {
    {
      '<leader>tm',
      '<cmd>Markview<cr>',
      desc = '[T]oggle [M]arkview',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
