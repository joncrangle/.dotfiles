return {
  { -- Autoformat
    'stevearc/conform.nvim',
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        astro = { { 'biome', 'prettierd', 'prettier' } },
        bash = { 'shfmt' },
        css = { { 'prettierd', 'prettier' } },
        -- Conform can also run multiple formatters sequentially
        go = { 'goimports', 'goimports-reviser', 'golines', 'gofmt' },
        html = { { 'prettierd', 'prettier' } },
        javascript = { { 'biome', 'prettierd', 'prettier' } },
        javascriptreact = { { 'biome', 'prettierd', 'prettier' } },
        json = { { 'biome', 'prettierd', 'prettier' } },
        lua = { 'stylua' },
        markdown = { 'markdownlint' },
        python = { 'isort', 'black' },
        sh = { 'shfmt' },
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
