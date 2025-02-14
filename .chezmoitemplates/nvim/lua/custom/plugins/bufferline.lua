return {
  ---@module 'bufferline'
  {
    'akinsho/bufferline.nvim',
    version = '*',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'echasnovski/mini.nvim',
      'catppuccin',
    },
    opts = function()
      local highlights = require('catppuccin.groups.integrations.bufferline').get()
      return {
        highlights = highlights,
        options = {
          mode = 'tabs',
          always_show_bufferline = false,
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
