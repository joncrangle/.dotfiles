return {
  {
    'folke/trouble.nvim',
    lazy = true,
    opts = {},
    cmd = 'Trouble',
    dependencies = { 'echasnovski/mini.nvim' },
    specs = {
      'folke/snacks.nvim',
      opts = function(_, opts)
        return vim.tbl_deep_extend('force', opts or {}, {
          picker = {
            actions = require('trouble.sources.snacks').actions,
            win = {
              input = {
                keys = { ['<c-t>'] = { 'trouble_open', mode = { 'n', 'i' } } },
              },
            },
          },
        })
      end,
    },
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
    event = 'VeryLazy',
    priority = 1000,
    init = function()
      vim.diagnostic.config({ virtual_text = false })
    end,
    opts = {},
  },
}
-- vim: ts=2 sts=2 sw=2 et
