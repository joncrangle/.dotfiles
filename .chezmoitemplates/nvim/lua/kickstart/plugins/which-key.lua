-- NOTE: Plugins can also be configured to run Lua code when they are loaded.
--
-- This is often very useful to both group configuration, as well as handle
-- lazy loading plugins that don't need to be loaded immediately at startup.
--
-- For example, in the following configuration, we use:
--  event = 'VimEnter'
--
-- which loads which-key before all the UI elements are loaded. Events can be
-- normal autocommands events (`:help autocmd-events`).
--
-- Then, because we use the `config` key, the configuration only runs
-- after the plugin has been loaded:
--  config = function() ... end

return {
  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    config = function() -- This is the function that runs, AFTER loading
      require('which-key').setup()

      -- Document existing key chains
      require('which-key').add {
        { '<leader>#', group = 'Harpoon2 List Item [1-5]' },
        { '<leader>c', group = '[C]ode', hidden = true },
        { '<leader>d', group = '[D]ocument', hidden = true },
        { '<leader>g', group = '[G]it', hidden = true },
        { '<leader>n', group = '[N]oice', hidden = true },
        { '<leader>r', group = '[R]ename', hidden = true },
        { '<leader>s', group = '[S]earch', hidden = true },
        { '<leader>t', group = '[T]oggle', hidden = true },
        { '<leader>w', group = '[W]orkspace', hidden = true },
        { '<leader>q', group = 'Persistent Sessions', hidden = true },
      }
      -- Ignore Harpoon2 list items
      for i = 1, 5 do
        require('which-key').add {
          { '<leader>' .. i, hidden = true },
          { '<leader>#' .. i, hidden = true },
        }
      end
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
