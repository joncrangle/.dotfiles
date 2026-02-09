return {
  ---@module 'conform'
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    ---@type conform.setupOpts
    opts = {
      notify_on_error = false,
      formatters_by_ft = {
        astro = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        bash = { 'shfmt' },
        css = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        go = { 'goimports', 'goimports-reviser', 'gofumpt' },
        html = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        http = { 'kulala' },
        javascript = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        json = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        lua = { 'stylua' },
        markdown = { 'oxfmt', 'markdown-toc' },
        ['markdown.mdx'] = { 'oxfmt', 'markdown-toc' },
        mysql = { 'sqlfluff' },
        plsql = { 'sqlfluff' },
        ps1 = { 'powershell_es' },
        python = { 'ruff_format' },
        sh = { 'shfmt', 'shellharden' },
        sql = { 'sqlfluff' },
        svelte = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        templ = { 'templ' },
        toml = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
        typst = { 'typstyle' },
        yaml = { 'oxfmt', 'prettierd', 'prettier', stop_after_first = true },
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
        ['markdown-toc'] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find '<!%-%- toc %-%->' then
                return true
              end
            end
            return false
          end,
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
    },
    keys = function()
      vim.api.nvim_create_user_command('FormatToggle', function()
        if vim.g.disable_autoformat then
          vim.g.disable_autoformat = false
          vim.notify('Autoformat-on-save enabled', vim.log.levels.INFO)
        else
          vim.g.disable_autoformat = true
          vim.notify('Autoformat-on-save disabled', vim.log.levels.INFO)
        end
      end, {
        desc = 'Toggle autoformat-on-save',
      })
      return {
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
      }
    end,
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
