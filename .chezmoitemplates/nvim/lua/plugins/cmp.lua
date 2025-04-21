return {
  ---@module 'blink.cmp'
  {
    'saghen/blink.cmp',
    build = 'cargo build --release',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'rafamadriz/friendly-snippets',
      'moyiz/blink-emoji.nvim',
      'Kaiser-Yang/blink-cmp-avante',
      'fang2hou/blink-copilot',
    },
    opts_extend = { 'sources.default' },
    ---@type blink.cmp.Config
    opts = {
      appearance = { nerd_font_variant = 'mono' },
      cmdline = {
        completion = {
          menu = {
            auto_show = function()
              return vim.fn.getcmdtype() == ':'
            end,
          },
        },
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = 'rounded',
          draw = { treesitter = { 'lsp' } },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = 'single',
          },
        },
        ghost_text = { enabled = true },
      },
      signature = {
        enabled = true,
        window = {
          border = 'single',
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'emoji', 'copilot' },
        per_filetype = {
          AvanteInput = { 'avante' },
          lua = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev', 'emoji', 'copilot' },
          sql = { 'snippets', 'dadbod', 'buffer', 'copilot' },
        },
        providers = {
          avante = { name = 'Avante', module = 'blink-cmp-avante' },
          copilot = { name = 'Copilot', module = 'blink-copilot', score_offset = 100, async = true },
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink', score_offset = 3 },
          emoji = { name = 'Emoji', module = 'blink-emoji', score_offset = 3 },
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },
      keymap = {
        preset = 'default',
        ['<C-l>'] = { 'snippet_forward', 'fallback' },
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
