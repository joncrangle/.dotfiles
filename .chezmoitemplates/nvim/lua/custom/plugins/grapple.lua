return {
  ---@module 'grapple'
  {
    'cbochs/grapple.nvim',
    lazy = true,
    dependencies = { 'echasnovski/mini.nvim' },
    opts = {
      scope = 'cwd',
      icons = true,
      tag_title = function() return 'Grapple Tags' end,
      win_opts = {
        width = 60,
        height = 12,
        border = 'rounded',
      }
    },
    keys = function()
      local keys = {
        { '<leader>h', '<cmd>Grapple toggle<cr>',      desc = 'Grapple a file' },
        { '<leader>H', '<cmd>Grapple toggle_tags<cr>', desc = 'Toggle Grapple menu' },
      }

      for i = 1, 9 do
        table.insert(keys, {
          '<leader>' .. i,
          '<cmd>Grapple select index=' .. i .. '<cr>',
          desc = 'Grapple tag ' .. i,
        })
      end
      return keys
    end
  },
}
-- vim: ts=2 sts=2 sw=2 et
