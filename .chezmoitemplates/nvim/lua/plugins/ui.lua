return {
  ---@module 'catppuccin'
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'catppuccin-mocha'
    end,
    ---@type CatppuccinOptions
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      integrations = {
        avante = true,
        blink_cmp = true,
        dadbod_ui = true,
        grug_far = true,
        lsp_trouble = true,
        mason = true,
        mini = { enabled = true },
        neotest = true,
        noice = true,
        snacks = true,
        which_key = true,
      },
      native_lsp = {
        enabled = true,
        underlines = {
          errors = { 'undercurl' },
          hints = { 'undercurl' },
          warnings = { 'undercurl' },
          information = { 'undercurl' },
        },
      },
      highlight_overrides = {
        mocha = function(mocha)
          return {
            CursorLine = { bg = 'NONE' },
            CursorLineNr = { fg = mocha.yellow },
            LineNrAbove = { fg = mocha.overlay1 },
            LineNrBelow = { fg = mocha.overlay1 },
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
    event = 'VimEnter',
    ---@type wk.Config|{}
    opts = {
      preset = 'modern',
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
    event = 'VimEnter',
    dependencies = { 'MunifTanjim/nui.nvim' },
    ---@type NoiceConfig
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
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
        -- Don't show "Agent service not initialized" message from copilot
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = 'Agent service not initialized' },
            },
          },
          opts = { skip = true },
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
      { '<leader>n', '<cmd>Noice<cr>', desc = '[N]otifications' },
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
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'echasnovski/mini.nvim' },
    event = { 'BufReadPost', 'BufNewFile' },
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        -- set an empty statusline till lualine loads
        vim.o.statusline = ' '
      else
        -- hide the statusline on the starter page
        vim.o.laststatus = 0
      end
    end,
    opts = {
      options = {
        theme = 'auto',
        globalstatus = true,
        extensions = {
          'lazy',
          'mason',
          'neo-tree',
          'nvim-dap-ui',
          'oil',
          'quickfix',
          'trouble',
        },
        disabled_filetypes = { statusline = { 'dashboard', 'lazygit' } },
      },
    },
  },
  ---@module 'bufferline'
  {
    'akinsho/bufferline.nvim',
    version = '*',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'echasnovski/mini.nvim',
      'catppuccin',
    },
    opts = function()
      local highlights = require('catppuccin.groups.integrations.bufferline').get()
      return {
        highlights = highlights,
        ---@type bufferline.Options
        options = {
          mode = 'tabs',
          always_show_bufferline = false,
        },
      }
    end,
  },
  ---@module 'edgy'
  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    opts = function()
      ---@type Edgy.Config|{}
      local opts = {
        bottom = {
          {
            ft = 'noice',
            size = { height = 0.3 },
            filter = function(_, win)
              return vim.api.nvim_win_get_config(win).relative == ''
            end,
          },
          'Trouble',
          { ft = 'qf', title = 'QuickFix' },
          {
            ft = 'help',
            size = { height = 0.3 },
            -- don't open help files in edgy that we're editing
            filter = function(buf)
              return vim.bo[buf].buftype == 'help'
            end,
          },
          { title = 'Neotest Output', ft = 'neotest-output-panel', size = { height = 15 } },
          { title = 'DB Query Result', ft = 'dbout' },
        },
        left = {
          { title = 'DBUI', ft = 'dbui', size = { width = 0.3 } },
        },
        right = {
          { title = 'Grug Far', ft = 'grug-far', size = { width = 0.4 } },
          { title = 'Neotest Summary', ft = 'neotest-summary' },
        },
        keys = {
          -- increase width
          ['<c-Right>'] = function(win)
            win:resize('width', 2)
          end,
          -- decrease width
          ['<c-Left>'] = function(win)
            win:resize('width', -2)
          end,
          -- increase height
          ['<c-Up>'] = function(win)
            win:resize('height', 2)
          end,
          -- decrease height
          ['<c-Down>'] = function(win)
            win:resize('height', -2)
          end,
        },
      }

      -- trouble
      for _, pos in ipairs { 'top', 'bottom', 'left', 'right' } do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = 'trouble',
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == 'split'
              and vim.w[win].trouble.relative == 'editor'
              and not vim.w[win].trouble_preview
          end,
        })
      end

      -- snacks terminal
      for _, pos in ipairs { 'top', 'bottom', 'left', 'right' } do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = 'snacks_terminal',
          size = { height = 0.4 },
          title = '%{b:snacks_terminal.id}: %{b:term_title}',
          filter = function(_, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == pos
              and vim.w[win].snacks_win.relative == 'editor'
              and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
