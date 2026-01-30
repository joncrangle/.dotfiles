return {
  {
    'NickvanDyke/opencode.nvim',
    config = function()
      vim.g.opencode_opts = {
        provider = { enabled = 'snacks' },
      }
      vim.o.autoread = true
      vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment under cursor', noremap = true })
      vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement under cursor', noremap = true })
    end,
    keys = {
      {
        '<c-.>',
        function()
          require('opencode').toggle()
        end,
        mode = { 'n', 't' },
        desc = 'Toggle opencode',
      },
      {
        '<c-a>',
        function()
          require('opencode').ask('@this: ', { submit = true })
        end,
        mode = { 'x', 'n' },
        desc = 'Ask opencode…',
      },
      {
        '<c-x>',
        function()
          require('opencode').select()
        end,
        mode = { 'x', 'n' },
        desc = 'Execute opencode action…',
      },
      {
        'go',
        function()
          return require('opencode').operator '@this '
        end,
        mode = { 'x', 'n' },
        desc = 'Add range to opencode',
      },
      {
        'goo',
        function()
          return require('opencode').operator '@this ' .. '_'
        end,
        desc = 'Add line to opencode',
        mode = { 'n' },
      },
      {
        '<S-C-u>',
        function()
          require('opencode').command 'session.half.page.up'
        end,
        desc = 'Scroll opencode up',
        mode = { 'n' },
      },
      {
        '<S-C-d>',
        function()
          require('opencode').command 'session.half.page.down'
        end,
        desc = 'Scroll opencode up',
        mode = { 'n' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
