return {
  { 'nvim-telescope/telescope-symbols.nvim', lazy = true, cmd = 'Telescope symbols', dependencies = { 'nvim-telescope/telescope.nvim' } },
  { 'jvgrootveld/telescope-zoxide', lazy = true, cmd = 'Telescope zoxide list', dependencies = { 'nvim-telescope/telescope.nvim' } },
  {
    'debugloop/telescope-undo.nvim',
    lazy = true,
    dependencies = {
      {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    opts = {
      extensions = {
        undo = {},
      },
    },
    config = function(_, opts)
      -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
      -- configs for us. We won't use data, as everything is in it's own namespace (telescope
      -- defaults, as well as each extension).
      require('telescope').setup(opts)
      require('telescope').load_extension 'undo'
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
