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
      'junkblocker/blink-cmp-wezterm',
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
            border = 'single',
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
          border = 'single',
        },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer', 'copilot', 'wezterm' },
        per_filetype = {
          AvanteInput = { 'avante', 'wezterm' },
          lua = { inherit_defaults = true, 'lazydev' },
          markdown = { inherit_defaults = true, 'emoji' },
          sql = { inherit_defaults = true, 'dadbod' },
        },
        providers = {
          avante = { name = 'Avante', module = 'blink-cmp-avante' },
          copilot = { name = 'Copilot', module = 'blink-copilot', score_offset = 100, async = true },
          dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink', score_offset = 3 },
          emoji = { name = 'Emoji', module = 'blink-emoji', score_offset = 3 },
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
          wezterm = { name = 'WezTerm', module = 'blink-cmp-wezterm' },
        },
      },
      keymap = {
        preset = 'super-tab',
        ['<Tab>'] = {
          function(cmp)
            if vim.b[vim.api.nvim_get_current_buf()].nes_state then
              cmp.hide()
              return (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
            end
            if cmp.snippet_active() then
              return cmp.accept()
            else
              return cmp.select_and_accept()
            end
          end,
          'snippet_forward',
          'fallback',
        },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
