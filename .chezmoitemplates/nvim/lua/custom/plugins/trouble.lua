return {
  'folke/trouble.nvim',
  lazy = true,
  opts = true,
  cmd = 'Trouble',
  dependencies = { 'echasnovski/mini.nvim' },
  keys = {
    {
      '<leader>x',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Toggle Trouble',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
