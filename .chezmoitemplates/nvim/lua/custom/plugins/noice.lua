return {
  {
    'rcarriga/nvim-notify',
    event = 'VimEnter',
    opts = {
      background_colour = '#000000',
    },
  },
  {
    'folke/noice.nvim',
    lazy = true,
    event = 'VimEnter',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
        signature = { auto_open = { enabled = false } },
      },
      cmdline = {
        view = 'cmdline',
      },
      status = {
        -- Statusline component for LSP progress notifications
        lsp_progress = { event = 'lsp', kind = 'progress' },
      },
      routes = {
        -- Ignore the typical vim change messages
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },
              { find = '; before #%d+' },
              { find = '%d fewer lines' },
              { find = '%d more lines' },
            },
          },
          opts = { skip = true },
        },
        -- Don't show lsp status messages in default view
        {
          filter = {
            event = 'lsp',
            kind = 'progress',
          },
          opts = { skip = true },
        },
        -- Don't show "No Information Available" hover message
        {
          filter = {
            event = 'notify',
            find = 'No information available',
          },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        lsp_doc_border = true,
        long_message_to_split = true,
      },
    },
    keys = {
      {
        '<leader>nt',
        '<cmd>NoiceTelescope<cr>',
        desc = '[N]oice [T]elescope',
      },
      {
        '<C-f>',
        function()
          if not require('noice.lsp').scroll(4) then
            return '<C-f>'
          end
        end,
        silent = true,
        expr = true,
        desc = 'Scroll forward',
        mode = { 'i', 'n', 's' },
      },
      {
        '<C-b>',
        function()
          if not require('noice.lsp').scroll(-4) then
            return '<C-b>'
          end
        end,
        silent = true,
        expr = true,
        desc = 'Scroll backward',
        mode = { 'i', 'n', 's' },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
