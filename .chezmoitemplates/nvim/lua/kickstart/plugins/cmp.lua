return {
  {
    'iguanacucumber/magazine.nvim',
    enabled = false,
    name = "nvim-cmp", -- Otherwise highlighting gets messed up
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'garymjr/nvim-snippets',
        opts = {
          friendly_snippets = true,
        },
        dependencies = { 'rafamadriz/friendly-snippets' },
        -- Think of <c-l> as moving to the right of your snippet expansion.
        --  So if you have a snippet that's like:
        --  function $name($args)
        --    $body
        --  end
        --
        -- <c-l> will move you to the right of each of the expansion locations.
        -- <c-h> is similar, except moving you backwards.
        keys = {
          {
            '<C-l>',
            function()
              if vim.snippet.active { direction = 1 } then
                vim.schedule(function()
                  vim.snippet.jump(1)
                end)
                return
              end
              return '<Tab>'
            end,
            expr = true,
            silent = true,
            mode = 'i',
          },
          {
            '<C-l>',
            function()
              vim.schedule(function()
                vim.snippet.jump(1)
              end)
            end,
            expr = true,
            silent = true,
            mode = 's',
          },
          {
            '<C-h>',
            function()
              if vim.snippet.active { direction = -1 } then
                vim.schedule(function()
                  vim.snippet.jump(-1)
                end)
                return
              end
              return '<S-Tab>'
            end,
            expr = true,
            silent = true,
            mode = { 'i', 's' },
          },
        },
      },

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
    },
    opts = {
      mappings = {
        disallow_fuzzy_matching = true,
        disallow_fullfuzzy_matching = true,
        disallow_partial_fuzzy_matching = true,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = true,
      },
      performance = {
        debounce = 0,
        throttle = 0,
      },
    },
    config = function()
      -- See `:help cmp`
      local cmp = require 'cmp'

      cmp.setup {
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},
        },
        sources = {
          {
            name = 'lazydev',
            -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
            group_index = 0,
          },
          { name = 'nvim_lsp' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'snippets' },
          { name = 'crates' },
          { name = 'path' },
        },
        ---@diagnostic disable-next-line: missing-fields
        formatting = {
          format = require('nvim-highlight-colors').format,
        },
      }

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' },
        }, {
          { name = 'cmdline' },
        }),
      })
    end,
  },
  {
    'saghen/blink.cmp',
    enabled = true,
    version = 'v0.*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      { 'rafamadriz/friendly-snippets' },
    },
    opts = {
      accept = { auto_brackets = { enabled = true } },
      nerd_font_variant = "mono",
      highlight = {
        use_nvim_cmp_as_default = true,
      },
      trigger = { signature_help = { enabled = true } },
      windows = {
        autocomplete = {
          border = 'single',
        },
        documentation = {
          border = 'single',
          auto_show = true,
        },
      },
      keymap = {
        accept = '<C-y>',
        snippet_forward = '<C-l>',
        snippet_backward = '<C-h>',
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
