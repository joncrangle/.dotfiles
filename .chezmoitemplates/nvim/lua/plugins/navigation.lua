return {
  { 'serhez/bento.nvim', event = { 'BufReadPost', 'BufNewFile' }, opts = {} },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
      { 'S', mode = { 'n', 'o', 'x' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
      { '<c-s>', mode = { 'c' }, function() require('flash').toggle() end, desc = 'Toggle Flash Search' },
    },
  },
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    keys = function()
      local smart_splits = require 'smart-splits'
      -- stylua: ignore
      local keys = {
        { '<A-h>', smart_splits.resize_left,       { desc = 'Resize split left' } },
        { '<A-j>', smart_splits.resize_down,       { desc = 'Resize split down' } },
        { '<A-k>', smart_splits.resize_up,         { desc = 'Resize split up' } },
        { '<A-l>', smart_splits.resize_right,      { desc = 'Resize split right' } },
        { '<C-h>', smart_splits.move_cursor_left,  { desc = 'Move to left split' } },
        { '<C-j>', smart_splits.move_cursor_down,  { desc = 'Move to below split' } },
        { '<C-k>', smart_splits.move_cursor_up,    { desc = 'Move to above split' } },
        { '<C-l>', smart_splits.move_cursor_right, { desc = 'Move to right split' } },
      }
      return keys
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = { options = vim.opt.sessionoptions:get() },
    keys = function()
      local wk = require 'which-key'
      -- stylua: ignore
      wk.add({
        { '<leader>p', group = '[P]ersistent Sessions', icon = { icon = ' ', color = 'azure' } },
        { '<leader>ps', function() require('persistence').load() end, desc = 'Restore Session' },
        { '<leader>pl', function() require('persistence').load { last = true } end, desc = 'Restore Last Session' },
        { '<leader>pd', function() require('persistence').stop() end, desc = "Don't Save Current Session" },
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
