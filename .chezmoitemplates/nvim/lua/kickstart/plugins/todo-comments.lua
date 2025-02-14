-- Highlight todo, notes, etc in comments
return {
  ---@module 'todo-comments'
  {
    'folke/todo-comments.nvim',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
-- vim: ts=2 sts=2 sw=2 et
