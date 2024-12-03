return {
  'folke/trouble.nvim',
  lazy = true,
  opts = {},
  cmd = 'Trouble',
  dependencies = { 'echasnovski/mini.nvim' },
  keys = {
    {
      '<leader>x',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Toggle Trouble',
    },
  },
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    priority = 1000,
    config = function()
      require('tiny-inline-diagnostic').setup()
    end
  },
}
-- vim: ts=2 sts=2 sw=2 et
