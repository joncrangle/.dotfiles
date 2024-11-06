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
  {                     -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      preset = 'modern',
    },
    config = function()
      local key_bindings = {
        { '<leader>#', desc = 'Grapple tag item [1-9]', icon = { icon = '󱡀', color = 'orange' } },
        { '<leader>a', group = '[A]vante', mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
        { '<leader>b', group = '[B]uffer', mode = { 'n', 'x' }, icon = { icon = '󰈔 ', color = 'cyan' } },
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
        { '<leader>d', group = '[D]ocument', icon = { icon = '󰈙', color = 'green' } },
        { '<leader>de', '<cmd>Telescope symbols<cr>', desc = '[D]ocument [E]moji picker', icon = { icon = '😀', color = 'green' } },
        { '<leader>g', group = '[G]it', icon = { icon = '', color = 'green' } },
        { '<leader>n', group = '[N]oice', icon = { icon = '󰈸', color = 'orange' } },
        { '<leader>r', group = '[R]ename', icon = { icon = '󰑕', color = 'orange' } },
        { '<leader>s', group = '[S]earch', icon = { icon = '', color = 'green' } },
        { '<leader>t', group = '[T]oggle', icon = { icon = '', color = 'orange' } },
        { '<leader>w', group = '[W]orkspace', icon = { icon = '', color = 'yellow' } },
        { '<leader>p', group = 'Persistent Sessions', icon = { icon = '', color = 'yellow' } },
        { '<leader>u', '<cmd>Telescope undo<cr>', desc = '[U]ndo history', icon = { icon = '', color = 'green' } },
        { '<leader>z', '<cmd>Telescope zoxide list<cr>', desc = '[Z]oxide list', icon = { icon = ' ', color = 'orange' } },
      }

      -- Add Grapple list items
      for i = 1, 9 do
        table.insert(key_bindings, { '<leader>' .. i, hidden = true })
        table.insert(key_bindings, { '<leader>#' .. i, hidden = true })
      end

      require('which-key').add(key_bindings)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
