return {
  {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  },
}
-- vim: ts=2 sts=2 sw=2 et
