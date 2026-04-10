return {
  ---@module 'catppuccin'
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    ---@type CatppuccinOptions
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      float = { transparent = true, solid = false },
      integrations = {
        dadbod_ui = true,
        grug_far = true,
        lsp_trouble = true,
        markview = true,
        mason = true,
        mini = { enabled = true },
        navic = {
          enabled = true,
          custom_bg = 'NONE',
        },
        neotest = true,
        noice = true,
        snacks = { enabled = true, indent_scope_color = 'lavender' },
        which_key = true,
      },
      highlight_overrides = {
        mocha = function(mocha)
          return {
            CursorLine = { bg = 'NONE' },
            CursorLineNr = { fg = mocha.yellow },
            LineNrAbove = { fg = mocha.subtext0 },
            LineNrBelow = { fg = mocha.subtext0 },
            LineNrInactive = { fg = mocha.overlay0 },
          }
        end,
      },
    },
  },
  {
    'brenoprata10/nvim-highlight-colors',
    lazy = true,
    event = 'BufReadPost',
    opts = { enable_tailwind = true },
  },
  ---@module 'which-key'
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    ---@type wk.Config|{}
    opts = {
      preset = 'helix',
      delay = 600,
    },
    config = function(_, opts)
      local wk = require 'which-key'
      -- stylua: ignore
      wk.add {
        { '<leader>b', group = '[B]uffer', mode = { 'n', 'x' }, icon = { icon = '󰈔 ', color = 'cyan' } },
        { '<leader>c', group = '[C]ode',   mode = { 'n', 'x' }, icon = { icon = ' ', color = 'green' } },
        { '<leader>d', group = '[D]ocument',                    icon = { icon = '󰈙', color = 'green' } },
        { '<leader>g', group = '[G]it',                         icon = { icon = '', color = 'green' } },
        { '<leader>r', group = '[R]ename',                      icon = { icon = '󰑕', color = 'orange' } },
        { '<leader>s', group = '[S]earch',                      icon = { icon = '', color = 'green' } },
        { '<leader>t', group = '[T]oggle/[T]est',               icon = { icon = '', color = 'orange' } },
        { '<leader>u', group = '[U]pdate',                      icon = { icon = '󰚰', color = 'orange' } },
        { '<leader>w', group = '[W]orkspace',                   icon = { icon = '', color = 'yellow' } },
      }
      wk.setup(opts)
    end,
  },
  ---@module 'noice'
  {
    'folke/noice.nvim',
    lazy = true,
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    ---@type NoiceConfig
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
        progress = { enabled = false },
        signature = { auto_open = { enabled = false } },
      },
      cmdline = { view = 'cmdline' },
      status = { lsp_progress = { event = 'lsp', kind = 'progress' } },
      routes = {
        -- Ignore the typical vim change messages
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d fewer lines' },
              { find = '%d more lines' },
              { find = 'lines yanked$' },
            },
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },
              { find = '; before #%d+' },
              { find = '%-%-No lines in buffer%-%-' },
              { find = 'No more valid diagnostics to move to' },
              { find = 'DB: Query' },
            },
          },
          view = 'mini',
        },
        -- Don't show "No Information Available" hover message
        {
          filter = {
            event = 'notify',
            find = 'No information available',
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = 'notify',
            any = {
              { find = 'No hunks to go to' },
            },
          },
          view = 'mini',
        },
        view = 'mini',
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
      { '<leader>m', '<cmd>Noice<cr>', desc = '[M]essages' },
    },
    config = function(_, opts)
      -- HACK: noice shows messages from before it was enabled,
      -- but this is not ideal when Lazy is installing plugins,
      -- so clear the messages in this case.
      if vim.o.filetype == 'lazy' then
        vim.cmd [[messages clear]]
      end
      require('noice').setup(opts)
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
