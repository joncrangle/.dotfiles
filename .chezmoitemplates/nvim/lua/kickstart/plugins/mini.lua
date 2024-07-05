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
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
