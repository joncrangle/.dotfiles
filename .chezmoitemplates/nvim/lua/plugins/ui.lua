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
        markdown = true,
        mini = { enabled = true },
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
      navic = { enabled = true, custom_bg = 'lualine' },
      neotest = true,
      neotree = true,
      noice = true,
      which_key = true,
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
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    ---@type NoiceConfig
    opts = {
      lsp = {
        override = {
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
    keys = function()
      local wk = require 'which-key'
      wk.add { '<leader>n', group = '[N]oice', icon = { icon = '󰈸', color = 'orange' } }
      return {
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
      }
    end,
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
}
-- vim: ts=2 sts=2 sw=2 et
