return {
  {
    'folke/sidekick.nvim',
    opts = {},
    keys = function()
      local wk = require 'which-key'
      wk.add {
        { '<leader>a', group = '[A]I', mode = { 'n', 'v' }, icon = { icon = ' ', color = 'azure' } },
      }
      return {
        {
          '<tab>',
          function()
            -- if there is a next edit, jump to it, otherwise apply it if any
            if not require('sidekick').nes_jump_or_apply() then
              return '<Tab>' -- fallback to normal tab
            end
          end,
          expr = true,
          desc = 'Goto/Apply Next Edit Suggestion',
        },
        {
          '<c-.>',
          function()
            require('sidekick.cli').focus()
          end,
          mode = { 'n', 'x', 'i', 't' },
          desc = 'Sidekick Switch Focus',
        },
        {
          '<leader>aa',
          function()
            require('sidekick.cli').toggle { name = 'opencode', focus = true }
          end,
          desc = 'Sidekick Toggle CLI',
          mode = { 'n', 'v' },
        },
        {
          '<leader>ap',
          function()
            require('sidekick.cli').prompt()
          end,
          desc = 'Sidekick Ask Prompt',
          mode = { 'n', 'v' },
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
