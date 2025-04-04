return {
  ---@module 'nvim-treesitter'
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-context',
        opts = { mode = 'cursor', max_lines = 3 },
        -- stylua: ignore
        keys = {
          { '[c', function() require('treesitter-context').go_to_context() end, desc = 'Goto context' },
        },
      },
      'nvim-treesitter/nvim-treesitter-textobjects',
      {
        'aaronik/treewalker.nvim',
        opts = {},
        -- stylua: ignore
        keys = {
          { '<Down>',  '<cmd>Treewalker Down<cr>',  desc = 'Next node' },
          { '<Right>', '<cmd>Treewalker Right<cr>', desc = 'Next child node' },
          { '<Up>',    '<cmd>Treewalker Up<cr>',    desc = 'Previous node' },
          { '<Left>',  '<cmd>Treewalker Left<cr>',  desc = 'Previous parent node' },
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
    opts = {
      vim.filetype.add {
        filename = {
          ['vifmrc'] = 'vim',
        },
        pattern = {
          ['.*/waybar/config'] = 'jsonc',
          ['.*/hypr/.+%.conf'] = 'hyprlang',
          ['%.env%.[%w_.-]+'] = 'sh',
        },
      },
      ensure_installed = {
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
        'lua_patterns',
        'markdown',
        'markdown_inline',
        'query',
        'regex',
        'rust',
        'ron',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true, disable = { 'ruby' } },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<CR>',
          scope_incremental = false,
          node_decremental = '<BS>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = { query = '@function.outer', desc = 'Select outer part of a function region' },
            ['if'] = { query = '@function.inner', desc = 'Select inner part of a function region' },
            ['aa'] = { query = '@parameter.outer', desc = 'Select outer part of a parameter/argument' },
            ['ia'] = { query = '@parameter.inner', desc = 'Select inner part of a parameter/argument' },
            ['ai'] = { query = '@conditional.outer', desc = 'Select outer part of a conditional' },
            ['ii'] = { query = '@conditional.inner', desc = 'Select inner part of a conditional' },
            ['al'] = { query = '@loop.outer', desc = 'Select outer part of a loop' },
            ['il'] = { query = '@loop.inner', desc = 'Select inner part of a loop' },
            ['am'] = {
              query = '@function.outer',
              desc = 'Select outer part of a method/function definition',
            },
            ['im'] = {
              query = '@function.inner',
              desc = 'Select inner part of a method/function definition',
            },
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']f'] = { query = '@call.outer', desc = 'Next function call start' },
            [']m'] = { query = '@function.outer', desc = 'Next method/function def start' },
            [']i'] = { query = '@conditional.outer', desc = 'Next conditional start' },
            [']l'] = { query = '@loop.outer', desc = 'Next loop start' },
          },
          goto_next_end = {
            [']F'] = { query = '@call.outer', desc = 'Next function call end' },
            [']M'] = { query = '@function.outer', desc = 'Next method/function def end' },
            [']I'] = { query = '@conditionaljouter', desc = 'Next conditional end' },
            [']L'] = { query = '@loop.outer', desc = 'Next loop end' },
          },
          goto_previous_start = {
            ['[f'] = { query = '@call.outer', desc = 'Prev function call start' },
            ['[m'] = { query = '@function.outer', desc = 'Prev method/function def start' },
            ['[i'] = { query = '@conditional.outer', desc = 'Prev conditional start' },
            ['[l'] = { query = '@loop.outer', desc = 'Prev loop start' },
          },
          goto_previous_end = {
            ['[F'] = { query = '@call.outer', desc = 'Prev function call end' },
            ['[M'] = { query = '@function.outer', desc = 'Prev method/function def end' },
            ['[I'] = { query = '@conditional.outer', desc = 'Prev conditional end' },
            ['[L'] = { query = '@loop.outer', desc = 'Prev loop end' },
          },
        },
      },
    },
    config = function(_, opts)
      ---@type table<string, ParserInfo|{}>
      local parser_configs = require('nvim-treesitter.parsers').get_parser_configs()

      parser_configs.lua_patterns = {
        install_info = {
          url = 'https://github.com/OXY2DEV/tree-sitter-lua_patterns',
          files = { 'src/parser.c' },
          branch = 'main',
        },
      }

      require('nvim-treesitter.configs').setup(opts)

      local ts_repeat_move = require 'nvim-treesitter.textobjects.repeatable_move'
      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move, { desc = 'Repeat last move' })
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite, { desc = 'Repeat last move (opposite)' })
      vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
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
