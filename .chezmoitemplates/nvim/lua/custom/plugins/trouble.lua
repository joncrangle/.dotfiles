return {
  {
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
  },
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    enabled = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
