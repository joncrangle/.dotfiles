return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Icon provider
      require('mini.icons').setup()
      -- Until other plugins support mini.icons natively
      MiniIcons.mock_nvim_web_devicons()

      require('mini.indentscope').setup {
        symbol = '│',
        options = { try_as_border = true },
        draw = {
          delay = 30,
          -- animation = require('mini.indentscope').gen_animation.none(),
        },
      }
    end,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'alpha',
          'dashboard',
          'fzf',
          'help',
          'lazy',
          'lazyterm',
          'mason',
          'neo-tree',
          'notify',
          'toggleterm',
          'Trouble',
          'trouble',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
