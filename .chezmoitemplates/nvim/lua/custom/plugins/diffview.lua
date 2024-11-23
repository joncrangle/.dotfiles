return {
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose' },
    opts = {},
    keys = {
      {
        '<leader>gd',
        function()
          if next(require('diffview.lib').views) == nil then
            vim.cmd 'DiffviewOpen'
          else
            vim.cmd 'tabclose'
          end
        end,
        desc = 'Toggle [D]iffview',
      },
    },
  },
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    config = function()
      require("hunk").setup()
    end,
  }
}
-- vim: ts=2 sts=2 sw=2 et
