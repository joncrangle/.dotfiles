return {
  { 'justinsgithub/wezterm-types', lazy = true, ft = 'lua' },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    opts = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
}
-- vim: ts=2 sts=2 sw=2 et
