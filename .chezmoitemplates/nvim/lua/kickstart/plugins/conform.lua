return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
      formatters_by_ft = {
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        astro = { { 'prettierd', 'prettier' } },
        bash = { 'shfmt' },
        css = { { 'prettierd', 'prettier' } },
        -- Conform can also run multiple formatters sequentially
        go = { 'goimports', 'goimports-reviser', 'golines', 'gofumpt' },
        html = { { 'prettierd', 'prettier' } },
        javascript = { { 'biome', 'prettierd', 'prettier' } },
        javascriptreact = { { 'biome', 'prettierd', 'prettier' } },
        json = { { 'biome', 'prettierd', 'prettier' } },
        lua = { 'stylua' },
        markdown = { 'markdownlint' },
        python = { 'ruff_format' },
        sh = { 'shfmt', 'shellharden' },
        svelte = { { 'biome', 'prettierd', 'prettier' } },
        templ = { 'templ' },
        toml = { { 'prettierd', 'prettier' } },
        typescript = { { 'biome', 'prettierd', 'prettier' } },
        typescriptreact = { { 'biome', 'prettierd', 'prettier' } },
        yaml = { { 'prettierd', 'prettier' } },
        zsh = { 'shfmt' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
