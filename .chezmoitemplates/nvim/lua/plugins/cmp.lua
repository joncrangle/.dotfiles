return {
  ---@module 'blink.cmp'
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'rafamadriz/friendly-snippets',
      'moyiz/blink-emoji.nvim',
      'Kaiser-Yang/blink-cmp-avante',
      {
        'Exafunction/windsurf.nvim',
        event = 'InsertEnter',
        build = ':Codeium Auth',
        config = function()
          require('codeium').setup {
            enable_cmp_source = false,
            default_filetype_enabled = false,
          }
        end,
      },
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
        keymap = { preset = 'inherit' },
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
            border = 'rounded',
          },
        },
        ghost_text = { enabled = true },
        trigger = {
          prefetch_on_insert = false,
          show_in_snippet = false,
        },
      },
      signature = {
        enabled = true,
        window = {
          border = 'rounded',
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'codeium' },
        per_filetype = {
          AvanteInput = { 'avante' },
          lua = { inherit_defaults = true, 'lazydev' },
          markdown = { inherit_defaults = true, 'emoji' },
          oil = { 'lsp', 'path', 'snippets', 'buffer' },
          sql = { inherit_defaults = true, 'dadbod' },
        },
        providers = {
          avante = { name = 'Avante', module = 'blink-cmp-avante' },
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink', score_offset = 3 },
          emoji = { name = 'Emoji', module = 'blink-emoji', score_offset = 3 },
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
          codeium = { name = 'Codeium', module = 'codeium.blink', async = true },
        },
      },
      keymap = {
        preset = 'super-tab',
        ['<Tab>'] = {
          'snippet_forward',
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'fallback',
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
