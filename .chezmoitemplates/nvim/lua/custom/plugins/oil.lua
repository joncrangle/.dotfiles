return {
  'stevearc/oil.nvim',
  enabled = false,
  event = 'VeryLazy',
  dependencies = { 'echasnovski/mini.nvim' },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'OilActionsPost',
      callback = function(event)
        if event.data.actions.type == 'move' then
          Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
        end
      end,
    })
  end,
  opts = {
    default_file_explorer = true,
    keymaps = {
      ['<C-f>'] = 'actions.preview_scroll_down',
      ['<C-b>'] = 'actions.preview_scroll_up',
    },
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      natural_order = true,
      ---@diagnostic disable-next-line: unused-local
      is_always_hidden = function(name, bufnr)
        return name == '.git' or name == '.jj'
      end,
    },
    win_options = {
      wrap = true,
    },
  },
  keys = {
    {
      '\\',
      '<cmd>Oil<cr>',
      desc = 'Open parent directory in oil.nvim',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
