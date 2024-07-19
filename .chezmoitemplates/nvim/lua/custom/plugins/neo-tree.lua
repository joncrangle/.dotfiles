return {
  'nvim-neo-tree/neo-tree.nvim',
  cmd = 'Neotree',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'echasnovski/mini.nvim',
    'MunifTanjim/nui.nvim',
  },
  opts = {
    filesystem = {
      hijack_netrw_behavior = 'disabled',
    },
  },
  keys = {
    {
      '<C-f>',
      '<cmd>Neotree toggle<cr>',
      desc = '[F]ile explorer',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
