return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod',                     lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
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
  {
    'kndndrj/nvim-dbee',
    dependencies = { 'MunifTanjim/nui.nvim' },
    build = function()
      require('dbee').install()
    end,
    cmd = { 'Dbee' },
    opts = {},
    keys = {
      {
        '<leader>td',
        function()
          require('dbee').toggle()
        end,
        desc = '[T]oggle [D]bee',
      },
      -- Scratch buffer mappings
      -- "BB" in visual mode = "run_selection"
      -- "BB" in normal mode = "run_file"
      -- Result buffer mappings
      -- next/previous page = "L"/"H"
      -- first/last page = "F"/"E"
      -- yank rows as json = "yaj" / yank all rows as json = "yaJ"
      -- yank rows as csv = "yac" / yank all rows as csv = "yaC"
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
