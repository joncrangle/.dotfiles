return {
  { 'gonstoll/wezterm-types', lazy = true, ft = 'lua' },
  ---@module 'lazydev'
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    ---@type lazydev.Config
    opts = {
      library = {
        { path = '${3rd}/busted/library', words = { 'describe' } },
        { path = '${3rd}/luassert/library', words = { 'assert' } },
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'wezterm-types/types', mods = { 'wezterm' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
      },
    },
  },
  ---@module 'todo-comments'
  {
    'folke/todo-comments.nvim',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    ---@type TodoOptions|{}
    opts = { signs = false },
  },
  ---@module 'quicker'
  {
    'stevearc/quicker.nvim',
    lazy = true,
    ---@type quicker.Config|{}
    opts = {
      -- stylua: ignore
      keys = {
        { '>', function() require('quicker').expand { before = 2, after = 2, add_to_existing = true } end, desc = 'Expand quickfix context' },
        { '<', function() require('quicker').collapse() end,                                               desc = 'Collapse quickfix context' },
      },
    },
    keys = {
      -- stylua: ignore
      { '<leader>q', function() require('quicker').toggle() end, desc = 'Toggle [Q]uicker', mode = 'n' },
    },
  },
  ---@module 'markview'
  {
    'OXY2DEV/markview.nvim',
    ft = { 'markdown', 'Avante' },
    opts = function()
      require('markview.extras.checkboxes').setup()
      local presets = require 'markview.presets'
      ---@type mkv.config
      return {
        ---@type config.markdown|{}
        markdown = {
          ---@type markdown.code_blocks|{}
          code_blocks = { sign = false },
          headings = presets.headings.marker,
        },
        preview = {
          filetypes = { 'Avante', 'md', 'markdown' },
          icon_provider = 'mini',
          ignore_buftypes = {},
        },
      }
    end,
    -- stylua: ignore
    keys = {
      { '<leader>tm', '<cmd>Markview toggle<cr>',                                    desc = '[T]oggle [M]arkview',    ft = 'markdown' },
      { '<leader>tc', '<cmd>Checkbox toggle<cr>',                                    desc = '[T]oggle [C]heckbox',    ft = 'markdown' },
      { '<<',         function() require('markview.extras.headings').decrease() end, desc = 'Decrease heading level', ft = 'markdown' },
      { '>>',         function() require('markview.extras.headings').increase() end, desc = 'Increase heading level', ft = 'markdown' },
    },
  },
  {
    'toppair/peek.nvim',
    ft = 'markdown',
    build = 'deno task --quiet build:fast',
    opts = {},
    keys = {
      {
        '<leader>tp',
        function()
          local peek = require 'peek'
          if peek.is_open() then
            peek.close()
          else
            peek.open()
          end
        end,
        desc = '[T]oggle Markdown [P]review',
        ft = 'markdown',
      },
    },
  },
  {
    'laytan/cloak.nvim',
    event = { 'BufReadPre *.env', 'BufReadPre *.http' },
    opts = {
      cloak_length = 12,
      patterns = {
        {
          file_pattern = '.env*',
          cloak_pattern = '=.+',
        },
        {
          file_pattern = '*.http',
          cloak_pattern = '(@[%w_]+=).+',
          replace = '%1',
        },
      },
    },
      -- stylua: ignore
    keys = {
      { '<leader>te', '<cmd>CloakPreviewLine<cr>', desc = '[T]oggle [E]nv for line' },
      { '<leader>tE', '<cmd>CloakToggle<cr>',      desc = '[T]oggle [E]nv for file' },
    },
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod', lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
      {
        'davesavic/dadbod-ui-yank',
        ft = { 'dbout' },
        cmd = { 'DBUIYankAsCSV', 'DBUIYankAsJSON', 'DBUIYankAsXML' },
        opts = {},
      -- stylua: ignore
        keys = {
          { '<leader>yc', ':DBUIYankAsCSV<CR>',  mode = { 'n', 'v' }, desc = 'Yank as CSV',  ft = 'dbout' },
          { '<leader>yj', ':DBUIYankAsJSON<CR>', mode = { 'n', 'v' }, desc = 'Yank as JSON', ft = 'dbout' },
          { '<leader>yx', ':DBUIYankAsXML<CR>',  mode = { 'n', 'v' }, desc = 'Yank as XML',  ft = 'dbout' },
        },
      },
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
    'mistweaverco/kulala.nvim',
    ft = { 'http' },
    init = function()
      vim.filetype.add {
        extension = {
          ['http'] = 'http',
        },
      }
    end,
    opts = {},
    -- stylua: ignore
    keys = {
      { '<leader>Rb', '<cmd>lua require("kulala").scratchpad()<cr>',              desc = 'Open scratchpad',          ft = 'http' },
      { '<leader>Rc', '<cmd>lua require("kulala").copy()<cr>',                    desc = 'Copy as cURL',             ft = 'http' },
      { '<leader>RC', '<cmd>lua require("kulala").from_curl()<cr>',               desc = 'Paste from curl',          ft = 'http' },
      { '<leader>Rg', '<cmd>lua require("kulala").download_graphql_schema()<cr>', desc = 'Download GraphQL schema',  ft = 'http' },
      { '<leader>Ri', '<cmd>lua require("kulala").inspect()<cr>',                 desc = 'Inspect current request',  ft = 'http' },
      { ']]',         '<cmd>lua require("kulala").jump_next()<cr>',               desc = 'Jump to next request',     ft = 'http' },
      { '[[',         '<cmd>lua require("kulala").jump_prev()<cr>',               desc = 'Jump to previous request', ft = 'http' },
      { '<leader>Rq', '<cmd>lua require("kulala").close()<cr>',                   desc = 'Close window',             ft = 'http' },
      { '<leader>Rr', '<cmd>lua require("kulala").replay()<cr>',                  desc = 'Replay the last request',  ft = 'http' },
      { '<C-e>',      '<cmd>lua require("kulala").run()<cr>',                     desc = 'Send the request',         ft = 'http' },
      { '<leader>RS', '<cmd>lua require("kulala").show_stats()<cr>',              desc = 'Show stats',               ft = 'http' },
      { '<leader>Rt', '<cmd>lua require("kulala").toggle_view()<cr>',             desc = 'Toggle headers/body',      ft = 'http' },
    },
  },
  {
    'OXY2DEV/patterns.nvim',
    cmd = 'Patterns',
    keys = {
      { '<leader>tr', '<cmd>Patterns explain<cr>', desc = '[T]oggle [R]egex explain' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
