return {
  { 'justinsgithub/wezterm-types', lazy = true },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      { path = 'wezterm-types', mods = { 'wezterm' } },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
