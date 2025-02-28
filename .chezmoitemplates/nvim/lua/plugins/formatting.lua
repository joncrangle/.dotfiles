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
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      formatters_by_ft = {
        astro = { 'prettierd', 'prettier', stop_after_first = true },
        bash = { 'shfmt' },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        go = { 'goimports', 'goimports-reviser', 'golines', 'gofumpt' },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        http = { 'kulala' },
        javascript = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        json = { 'biome', 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        markdown = { 'markdownlint-cli2', 'markdown-toc' },
        ['markdown.mdx'] = { 'prettier', 'markdownlint-cli2', 'markdown-toc' },
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
        injected = { options = { ignore_errors = true } },
        kulala = {
          command = 'kulala-fmt',
          args = { 'format', '$FILENAME' },
          stdin = false,
        },
        sqlfluff = {
          args = { 'format', '--dialect=ansi', '-' },
        },
        formatters = {
          ['markdown-toc'] = {
            condition = function(_, ctx)
              for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                if line:find '<!%-%- toc %-%->' then
                  return true
                end
              end
            end,
          },
          ['markdownlint-cli2'] = {
            condition = function(_, ctx)
              local diag = vim.tbl_filter(function(d)
                return d.source == 'markdownlint'
              end, vim.diagnostic.get(ctx.buf))
              return #diag > 0
            end,
          },
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
    },
    config = function(_, opts)
      require('conform').setup(opts)

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
