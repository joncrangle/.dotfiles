return {
  { 'justinsgithub/wezterm-types', lazy = true, ft = 'lua' },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    opts = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
