return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod',                     lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
      {
        'davesavic/dadbod-ui-yank',
        ft = { 'dbout' },
        cmd = { 'DBUIYankAsCSV', 'DBUIYankAsJSON', 'DBUIYankAsXML' },
        opts = {},
        keys = {
          { '<leader>yc', ':DBUIYankAsCSV<CR>',  mode = { 'n', 'v' }, desc = 'Yank as CSV',  ft = 'dbout' },
          { '<leader>yj', ':DBUIYankAsJSON<CR>', mode = { 'n', 'v' }, desc = 'Yank as JSON', ft = 'dbout' },
          { '<leader>yx', ':DBUIYankAsXML<CR>',  mode = { 'n', 'v' }, desc = 'Yank as XML',  ft = 'dbout' },
        },
      }
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
