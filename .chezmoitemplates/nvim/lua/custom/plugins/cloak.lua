return {
  {
    'laytan/cloak.nvim',
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
    init = function()
      vim.keymap.set('n', '<leader>te', '<cmd>CloakPreviewLine<cr>', { desc = '[T]oggle [E]nv for line' })
      vim.keymap.set('n', '<leader>tE', '<cmd>CloakToggle<cr>', { desc = '[T]oggle [E]nv for file' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
