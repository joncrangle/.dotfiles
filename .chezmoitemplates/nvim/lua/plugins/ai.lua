local disabled = false

return {
  {
    'folke/sidekick.nvim',
    opts = { nes = { enabled = true } },
    config = function(_, opts)
      require('sidekick').setup(opts)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'SidekickNesHide',
        callback = function()
          if disabled then
            disabled = false
            require('tiny-inline-diagnostic').enable()
          end
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'SidekickNesShow',
        callback = function()
          disabled = true
          require('tiny-inline-diagnostic').disable()
        end,
      })
    end,
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
            require('sidekick.cli').toggle { name = 'opencode', focus = true }
          end,
          mode = { 'n', 'x', 'i', 't' },
          desc = 'Sidekick Toggle',
        },
        {
          '<leader>at',
          function()
            require('sidekick.cli').send { msg = '{this}' }
          end,
          mode = { 'x', 'n' },
          desc = 'Send This',
        },
        {
          '<leader>af',
          function()
            require('sidekick.cli').send { msg = '{file}' }
          end,
          desc = 'Send File',
        },
        {
          '<leader>av',
          function()
            require('sidekick.cli').send { msg = '{selection}' }
          end,
          mode = { 'x' },
          desc = 'Send Visual Selection',
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
