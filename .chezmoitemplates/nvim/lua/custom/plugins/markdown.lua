return {
  ---@module 'render-markdown'
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    ft = { 'markdown', 'Avante' },
    opts = {
      file_types = { 'markdown', 'Avante' },
    },
    keys = {
      {
        '<leader>tm',
        '<cmd>RenderMarkdown toggle<cr>',
        ft = 'markdown',
        desc = '[T]oggle [M]arkdown',
      },
    },
  },
  ---@module 'helpview'
  {
    'OXY2DEV/helpview.nvim',
    lazy = false,
    ft = 'help',
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = 'cd app && npm install && git restore .',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
    end,
    keys = {
      { '<leader>tp', '<cmd>MarkdownPreviewToggle<cr>', desc = '[T]oggle Markdown [P]review' },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
