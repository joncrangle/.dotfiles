-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
-- used for completion, annotations and signatures of Neovim apis
return {
  { 'Bilal2453/luvit-meta',        lazy = true, ft = 'lua' },
  { 'gonstoll/wezterm-types', lazy = true, ft = 'lua' },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library',  words = { 'vim%.uv' } },
        { path = 'wezterm-types/types', mods = { 'wezterm' } },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
