return {
  ---@module 'conform'
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
      {
        '<leader>tf',
        '<cmd>FormatToggle<cr>',
        mode = 'n',
        desc = '[T]oggle [F]ormat on save',
      },
    },
    opts = {
      notify_on_error = false,
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
        mysql = { 'sqlfluff' },
        plsql = { 'sqlfluff' },
        python = { 'ruff_format' },
        sh = { 'shfmt', 'shellharden' },
        sql = { 'sqlfluff' },
        svelte = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        templ = { 'templ' },
        toml = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        zsh = { 'shfmt' },
      },
      formatters = {
        sqlfluff = {
          args = { 'format', '--dialect=ansi', '-' },
        },
      },
    },
    config = function()
      require('conform').setup {
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_format = 'fallback' }
        end,
      }

      vim.api.nvim_create_user_command('FormatToggle', function()
        if vim.g.disable_autoformat then
          vim.g.disable_autoformat = false
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = 'Toggle autoformat-on-save',
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
