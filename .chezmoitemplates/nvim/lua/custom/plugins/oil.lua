return {
  'stevearc/oil.nvim',
  lazy = true,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
      ---@diagnostic disable-next-line: unused-local
      is_always_hidden = function(name, bufnr)
        return name == '.git'
      end,
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
