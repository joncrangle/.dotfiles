return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.nvim',
    },
    ft = { 'markdown' },
    opts = {},
    keys = {
      {
        '<leader>tm',
        '<cmd>RenderMarkdown toggle<cr>',
        ft = 'markdown',
        desc = '[T]oggle [M]arkdown',
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install && git restore .",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>tp", "<cmd>MarkdownPreviewToggle<cr>", desc = "[T]oggle Markdown [P]review" },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
