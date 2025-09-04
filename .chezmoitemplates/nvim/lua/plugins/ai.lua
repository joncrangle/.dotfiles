return {
  {
    'copilotlsp-nvim/copilot-lsp',
    event = { 'BufReadPre', 'BufNewFile' },
    enabled = true,
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable 'copilot_ls'
      vim.keymap.set('n', '<tab>', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local state = vim.b[bufnr].nes_state
        if state then
          -- Try to jump to the start of the suggestion edit.
          -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
          local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
            or (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
          return nil
        else
          -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
          return '<C-i>'
        end
      end, { desc = 'Accept Copilot NES suggestion', expr = true })
    end,
  },
  {
    'NickvanDyke/opencode.nvim',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    keys = function()
      local wk = require 'which-key'
      wk.add {
        { '<leader>o', group = '[O]pencode', mode = { 'n', 'v' }, icon = { icon = ' ', color = 'blue' } },
      }
      -- stylua: ignore
      return {
      { '<leader>oA', function() require('opencode').ask() end, desc = 'Ask opencode', },
      { '<leader>oa', function() require('opencode').ask('@cursor: ') end, desc = 'Ask opencode about this', mode = 'n', },
      { '<leader>oa', function() require('opencode').ask('@selection: ') end, desc = 'Ask opencode about selection', mode = 'v', },
      { '<leader>ot', function() require('opencode').toggle() end, desc = 'Toggle embedded opencode', },
      { '<leader>on', function() require('opencode').command('session_new') end, desc = 'New session', },
      { '<leader>oy', function() require('opencode').command('messages_copy') end, desc = 'Copy last message', },
      { '<S-C-u>',    function() require('opencode').command('messages_half_page_up') end, desc = 'Scroll messages up', },
      { '<S-C-d>',    function() require('opencode').command('messages_half_page_down') end, desc = 'Scroll messages down', },
      { '<leader>os', function() require('opencode').select() end, desc = 'Select prompt', mode = { 'n', 'v', }, },
    }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
