return {
  {
    'allaman/emoji.nvim',
    lazy = true,
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/nvim-cmp',
    },
    opts = {
      enable_cmp_integration = true,
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
