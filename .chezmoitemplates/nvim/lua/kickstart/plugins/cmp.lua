return {
  {
    'saghen/blink.cmp',
    build = 'cargo build --release',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      { 'rafamadriz/friendly-snippets' },
      'moyiz/blink-emoji.nvim',
    },
    opts_extend = { 'sources.default' },
    opts = {
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = { border = 'single', draw = { treesitter = { 'lsp' } } },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = 'single',
          },
        },
      },
      signature = {
        enabled = true,
        window = {
          border = 'single',
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev', 'dadbod', 'emoji' },
        per_filetype = {
          AvanteInput = {},
        },
        providers = {
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink', score_offset = 3 },
          emoji = { name = 'Emoji', module = 'blink-emoji', score_offset = 3 },
        },
      },
      keymap = {
        preset = 'default',
        ['<C-/>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-l>'] = { 'snippet_forward', 'fallback' },
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
        cmdline = { preset = 'super-tab' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
