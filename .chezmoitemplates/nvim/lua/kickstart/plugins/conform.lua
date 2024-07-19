return {
  {
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
        astro = { 'prettierd', 'prettier', stop_after_first = true },
        bash = { 'shfmt' },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        go = { 'goimports', 'goimports-reviser', 'golines', 'gofumpt' },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        javascript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        json = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        markdown = { 'markdownlint' },
        python = { 'ruff_format' },
        sh = { 'shfmt', 'shellharden' },
        svelte = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        templ = { 'templ' },
        toml = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        zsh = { 'shfmt' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
