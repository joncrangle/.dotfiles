return {
  {
    'theprimeagen/harpoon',
    branch = 'harpoon2',
    lazy = true,
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:extend {
        UI_CREATE = function(cx)
          vim.keymap.set('n', '<C-v>', function()
            harpoon.ui:select_menu_item { vsplit = true }
          end, { buffer = cx.bufnr })

          vim.keymap.set('n', '<C-x>', function()
            harpoon.ui:select_menu_item { split = true }
          end, { buffer = cx.bufnr })

          vim.keymap.set('n', '<C-t>', function()
            harpoon.ui:select_menu_item { tabedit = true }
          end, { buffer = cx.bufnr })
        end,
      }
    end,
    keys = function()
      local keys = {
        {
          '<leader>h',
          function()
            local harpoon = require 'harpoon'
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = '[H]arpoon2 quick menu',
        },
        {
          '<leader>a',
          function()
            require('harpoon'):list():add()
          end,
          desc = '[A]dd file to Harpoon2',
        },
      }

      for i = 1, 5 do
        table.insert(keys, {
          '<leader>' .. i,
          function()
            require('harpoon'):list():select(i)
          end,
          desc = 'Harpoon2 list ' .. i,
        })
      end
      return keys
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
