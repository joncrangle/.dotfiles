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
    'smart-splits-nvim/smart-splits.nvim',
    version = '^3.0.0',
    lazy = false,
    dependencies = {
      { 'smart-splits-nvim/backend-wezterm', main = 'smart-splits-backend-wezterm', opts = {} },
      { 'smart-splits-nvim/backend-ghostty', main = 'smart-splits-backend-ghostty', opts = {} },
    },
    opts = {
      mux = { backend = { 'smart-splits-backend-wezterm', 'smart-splits-backend-ghostty' } },
      move = { at_edge = 'stop' },
    },
    -- stylua: ignore
    keys = {
      { '<A-h>', function() require('smart-splits').resize_left() end,        desc = 'Resize split left' },
      { '<A-j>', function() require('smart-splits').resize_down() end,        desc = 'Resize split down' },
      { '<A-k>', function() require('smart-splits').resize_up() end,          desc = 'Resize split up' },
      { '<A-l>', function() require('smart-splits').resize_right() end,       desc = 'Resize split right' },
      { '<C-h>', function() require('smart-splits').move_cursor_left() end,   desc = 'Move to left split' },
      { '<C-j>', function() require('smart-splits').move_cursor_down() end,   desc = 'Move to below split' },
      { '<C-k>', function() require('smart-splits').move_cursor_up() end,     desc = 'Move to above split' },
      { '<C-l>', function() require('smart-splits').move_cursor_right() end,  desc = 'Move to right split' },
    },
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
