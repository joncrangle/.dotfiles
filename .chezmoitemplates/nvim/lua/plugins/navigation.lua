return {
  {
    'serhez/bento.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function(_, opts)
      require('bento').setup(opts)
      local bento_api = require 'bento.api'
      bento_api.register_expand_key ';'
      bento_api.register_last_buffer_key ';'
      bento_api.register_collapse_key '<Esc>'
      bento_api.register_prev_page_key '['
      bento_api.register_next_page_key ']'
      bento_api.register_action('open', {
        key = '<CR>',
        action = bento_api.actions.open,
        hl = 'DiagnosticVirtualTextHint',
      })
      bento_api.register_action('delete', {
        key = '<BS>',
        action = bento_api.actions.delete,
        hl = 'DiagnosticVirtualTextError',
      })
      bento_api.register_action('vsplit', {
        key = '|',
        action = bento_api.actions.vsplit,
        hl = 'DiagnosticVirtualTextInfo',
      })
      bento_api.register_action('split', {
        key = '_',
        action = bento_api.actions.split,
        hl = 'DiagnosticVirtualTextInfo',
      })
      bento_api.register_action('lock', {
        key = '*',
        action = bento_api.actions.lock,
        hl = 'DiagnosticVirtualTextWarn',
      })
      bento_api.set_default_action 'open'
    end,
  },
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
    opts = {},
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
