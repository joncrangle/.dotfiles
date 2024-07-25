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
      '<leader>-',
      '<cmd>Neotree toggle<cr>',
      desc = 'Neo-tree file explorer',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
