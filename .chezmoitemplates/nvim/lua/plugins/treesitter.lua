return {
  ---@module 'nvim-treesitter'
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-context',
        opts = { mode = 'cursor', max_lines = 3 },
        -- stylua: ignore
        keys = {
          { '[c', function() require('treesitter-context').go_to_context() end, desc = 'Goto context' },
        },
      },
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        opts = { select = { lookahead = true } },
        keys = function()
          local ts_move = require 'nvim-treesitter-textobjects.move'
          local ts_select = require 'nvim-treesitter-textobjects.select'
          local ts_swap = require 'nvim-treesitter-textobjects.swap'
          local ts_repeat_move = require 'nvim-treesitter-textobjects.repeatable_move'
          -- stylua: ignore
          local keys = {
            -- move
            { mode = { 'n', 'x', 'o' }, '[f', function() ts_move.goto_previous_start('@function.outer', 'textobjects') end,    desc = 'Previous function start' },
            { mode = { 'n', 'x', 'o' }, ']f', function() ts_move.goto_next_start("@function.outer", "textobjects") end,        desc = 'Next function start' },
            { mode = { 'n', 'x', 'o' }, '[F', function() ts_move.goto_previous_end('@function.outer', 'textobjects') end,      desc = 'Previous function end' },
            { mode = { 'n', 'x', 'o' }, ']F', function() ts_move.goto_next_end("@function.outer", "textobjects") end,          desc = 'Next function end' },
            { mode = { 'n', 'x', 'o' }, '[a', function() ts_move.goto_previous_start('@parameter.outer', 'textobjects') end,   desc = 'Previous argument start' },
            { mode = { 'n', 'x', 'o' }, ']a', function() ts_move.goto_next_start("@parameter.outer", "textobjects") end,       desc = 'Next argument start' },
            { mode = { 'n', 'x', 'o' }, '[A', function() ts_move.goto_previous_end('@parameter.outer', 'textobjects') end,     desc = 'Previous argument end' },
            { mode = { 'n', 'x', 'o' }, ']A', function() ts_move.goto_next_end("@parameter.outer", "textobjects") end,         desc = 'Next argument end' },
            { mode = { 'n', 'x', 'o' }, '[i', function() ts_move.goto_previous_start('@conditional.outer', 'textobjects') end, desc = 'Previous conditional start' },
            { mode = { 'n', 'x', 'o' }, ']i', function() ts_move.goto_next_start("@conditional.outer", "textobjects") end,     desc = 'Next conditional start' },
            { mode = { 'n', 'x', 'o' }, '[I', function() ts_move.goto_previous_end('@conditional.outer', 'textobjects') end,   desc = 'Previous conditional end' },
            { mode = { 'n', 'x', 'o' }, ']I', function() ts_move.goto_next_end("@conditional.outer", "textobjects") end,       desc = 'Next loop end' },
            { mode = { 'n', 'x', 'o' }, '[l', function() ts_move.goto_previous_start('@loop.outer', 'textobjects') end,        desc = 'Previous loop start' },
            { mode = { 'n', 'x', 'o' }, ']l', function() ts_move.goto_next_start("@loop.outer", "textobjects") end,            desc = 'Next loop start' },
            { mode = { 'n', 'x', 'o' }, '[L', function() ts_move.goto_previous_end('@loop.outer', 'textobjects') end,          desc = 'Previous loop end' },
            { mode = { 'n', 'x', 'o' }, ']L', function() ts_move.goto_next_end("@loop.outer", "textobjects") end,              desc = 'Next loop end' },
            { mode = { 'n', 'x', 'o' }, '[[', function() ts_move.goto_previous_start('@block.outer', 'textobjects') end,       desc = 'Previous block start' },
            { mode = { 'n', 'x', 'o' }, ']]', function() ts_move.goto_next_start("@block.outer", "textobjects") end,           desc = 'Next block start' },
            -- select
            { mode = { 'n', 'x', 'o' }, 'af', function() ts_select.select_textobject("@function.outer", "textobjects") end,    desc = 'Select outer part of a function region' },
            { mode = { 'n', 'x', 'o' }, 'if', function() ts_select.select_textobject("@function.inner", "textobjects") end,    desc = 'Select inner part of a function region' },
            { mode = { 'n', 'x', 'o' }, 'aa', function() ts_select.select_textobject("@parameter.outer", "textobjects") end,   desc = 'Select outer part of a parameter/argument' },
            { mode = { 'n', 'x', 'o' }, 'ia', function() ts_select.select_textobject("@parameter.inner", "textobjects") end,   desc = 'Select inner part of a parameter/argument' },
            { mode = { 'n', 'x', 'o' }, 'ai', function() ts_select.select_textobject("@conditional.outer", "textobjects") end, desc = 'Select outer part of a conditional' },
            { mode = { 'n', 'x', 'o' }, 'ii', function() ts_select.select_textobject("@conditional.inner", "textobjects") end, desc = 'Select inner part of a conditional' },
            { mode = { 'n', 'x', 'o' }, 'al', function() ts_select.select_textobject("@loop.outer", "textobjects") end,        desc = 'Select outer part of a loop' },
            { mode = { 'n', 'x', 'o' }, 'il', function() ts_select.select_textobject("@loop.inner", "textobjects") end,        desc = 'Select inner part of a loop' },
            -- swap
            { mode = { 'n', 'x', 'o' }, '<leader>cs', function() ts_swap.swap_next "@parameter.inner" end,                     desc = 'Swap next argument' },
            { mode = { 'n', 'x', 'o' }, '<leader>cS', function() ts_swap.swap_previous "@parameter.inner" end,                 desc = 'Swap previous argument' },
            -- repeatable move
            { mode = { 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move_next,                                             desc = 'Repeat last move' },
            { mode = { 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_previous,                                         desc = 'Repeat previous move' },
          }
          return keys
        end,
      },
      {
        'aaronik/treewalker.nvim',
        opts = { select = true },
        -- stylua: ignore
        keys = {
          { mode = { 'n', 'v' }, '<CR>',  '<cmd>Treewalker Left<cr>',    desc = 'Expand Selection' },
          { mode = { 'n', 'v' }, '<BS>',    '<cmd>Treewalker Right<cr>', desc = 'Decrement Selection' },
        },
      },
      {
        'Wansmer/treesj',
        opts = { use_default_keymaps = false, max_join_length = 150 },
        keys = { { '<leader>j', '<cmd>TSJToggle<cr>', desc = '[J]oin Toggle' } },
      },
    },
    build = ':TSUpdate',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = { 'TSInstall', 'TSInstallInfo', 'TSBufEnable', 'TSBufDisable', 'TSEnable', 'TSDisable', 'TSModuleInfo', 'TSUpdate' },
    ---@type TSConfig|{}
    opts = {},
    config = function(_, opts)
      vim.filetype.add {
        filename = {
          ['vifmrc'] = 'vim',
        },
        pattern = {
          ['.*/waybar/config'] = 'jsonc',
          ['.*/hypr/.+%.conf'] = 'hyprlang',
          ['%.env%.[%w_.-]+'] = 'sh',
        },
      }

      local ensure_installed = {
        'bash',
        'c',
        'diff',
        'git_config',
        'go',
        'html',
        'http',
        'hyprlang',
        'javascript',
        'lua',
        'luadoc',
        'markdown_inline',
        'query',
        'regex',
        'rust',
        'ron',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }
      local isnt_installed = function(lang)
        return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
      end
      local to_install = vim.tbl_filter(isnt_installed, ensure_installed)
      if #to_install > 0 then
        require('nvim-treesitter').install(to_install)
      end

      local filetypes = vim.iter(ensure_installed):map(vim.treesitter.language.get_filetypes):flatten():totable()
      vim.list_extend(filetypes, { 'markdown', 'pandoc' })
      local ts_start = function(ev)
        vim.treesitter.start(ev.buf)
      end
      vim.api.nvim_create_autocmd('FileType', { pattern = filetypes, callback = ts_start })
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    lazy = true,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = {
      'astro',
      'glimmer',
      'handlebars',
      'hbs',
      'html',
      'javascript',
      'javascriptreact',
      'jsx',
      'markdown',
      'php',
      'rescript',
      'svelte',
      'tsx',
      'twig',
      'typescript',
      'typescriptreact',
      'vue',
      'xml',
    },
    opts = {},
  },
}
-- vim: ts=2 sts=2 sw=2 et
