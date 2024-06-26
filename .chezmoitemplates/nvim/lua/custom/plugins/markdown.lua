return {
  'MeanderingProgrammer/markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown' },
  opts = true,
  keys = {
    {
      '<leader>tm',
      '<cmd>RenderMarkdownToggle<cr>',
      desc = '[T]oggle [m]arkdown preview',
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
