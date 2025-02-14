return {
  ---@module 'smart-splits'
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    keys = function()
      local smart_splits = require 'smart-splits'
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
}
-- vim: ts=2 sts=2 sw=2 et
