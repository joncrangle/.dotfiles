return {
  'akinsho/bufferline.nvim',
  version = '*',
  lazy = true,
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'echasnovski/mini.nvim',
    'catppuccin',
  },
  config = function()
    require('bufferline').setup {
      highlights = require('catppuccin.groups.integrations.bufferline').get(),
      options = {
        mode = 'tabs',
        always_show_bufferline = false,
      },
    }
  end,
}
-- vim: ts=2 sts=2 sw=2 et
