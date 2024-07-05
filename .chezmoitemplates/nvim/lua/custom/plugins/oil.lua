return {
  'stevearc/oil.nvim',
  lazy = true,
  dependencies = { 'echasnovski/mini.nvim' },
  opts = {
    default_file_explorer = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      natural_order = true,
      ---@diagnostic disable-next-line: unused-local
      is_always_hidden = function(name, bufnr)
        return name == '.git'
      end,
    },
    win_options = {
      wrap = true,
    },
  },
  keys = {
    {
      '<leader>-',
      '<cmd>Oil<cr>',
      desc = 'Open parent directory in oil.nvim',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
