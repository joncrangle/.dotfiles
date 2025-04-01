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
            SnacksIndentScope = { fg = mocha.lavender },
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
    event = 'VeryLazy',
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
    opts = function()
      -- Custom lualine extension for grapple and snacks
      local function get_statusline()
        local filetype = vim.bo.filetype
        local title = filetype
        local meta = ''

        if filetype == 'grapple' then
          title = 'Grapple'
          meta = require('grapple').statusline() or ''
        elseif filetype == 'snacks_terminal' then
          title = ' Terminal'
          meta = vim.fn.expand('%:t'):match '.*:(%S+)$' or vim.fn.expand '%:t'
        elseif filetype == 'snacks_picker_list' then
          title = '🍿 Explorer'
          meta = vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
        elseif filetype == 'snacks_picker_input' then
          title = '🍿 Picker'
          meta = ''
        end

        return title, meta
      end

      local lualine_custom = {
        sections = {
          lualine_a = {
            function()
              local title, _ = get_statusline()
              return title
            end,
          },
          lualine_b = {
            function()
              local _, meta = get_statusline()
              return meta
            end,
          },
        },
        filetypes = {
          'grapple',
          'snacks_picker_input',
          'snacks_picker_list',
          'snacks_terminal',
        },
      }

      return {
        options = {
          theme = 'auto',
          always_show_tabline = false,
          -- section_separators = { left = '', right = '' },
          globalstatus = true,
          disabled_filetypes = { statusline = { 'snacks_dashboard', 'lazygit' } },
        },
        extensions = {
          lualine_custom,
          'lazy',
          'mason',
          'nvim-dap-ui',
          'oil',
          'quickfix',
          'trouble',
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = {
            { 'diagnostics' },
            { 'filetype', icon_only = true, separator = '', padding = { left = 1, right = 0 } },
            {
              function()
                local function truncate_path(path, max_length)
                  local parts = vim.split(path, '[\\/]')

                  if #parts > max_length then
                    parts = { parts[1], '…', unpack(parts, #parts - max_length + 2, #parts) }
                  end

                  return table.concat(parts, package.config:sub(1, 1))
                end

                local filename = vim.fn.expand '%:t' --[[@as string]]
                local filepath = vim.fn.expand '%:.' --[[@as string]]
                local dir = filepath:gsub(filename, '')
                local truncated_dir = truncate_path(dir, 3)
                local filename_hl = vim.bo.modified and '%#MatchParen#' or '%#Title#'
                local readonly_icon = vim.bo.readonly and ' 󰌾 ' or ''
                local grapple = ''

                if package.loaded['grapple'] then
                  grapple = require('grapple').exists() and ' 󰛢 ' .. require('grapple').name_or_index() or ''
                end

                return '%#Italic#'
                  .. truncated_dir
                  .. '%#Normal#'
                  .. filename_hl
                  .. filename
                  .. '%#Normal#'
                  .. (grapple ~= '' and '%#GrappleName#' .. grapple or '')
                  .. '%#Normal#'
                  .. readonly_icon
              end,
              padding = { left = 0, right = 1 },
            },
          },
          lualine_x = {
            {
              function()
                return '  ' .. require('dap').status()
              end,
              cond = function()
                return package.loaded['dap'] and require('dap').status() ~= ''
              end,
              color = function()
                return { fg = Snacks.util.color 'Debug' }
              end,
            },
            { 'diff' },
            { 'lsp_status', icon = '󰅩' },
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        tabline = {
          lualine_a = {
            {
              function()
                return '󰈙'
              end,
            },
          },
          lualine_b = {
            {
              'tabs',
              mode = 1,
              max_length = function()
                return vim.o.columns
              end,
              component_separators = { left = '', right = '' },
              section_separators = { left = '', right = '' },
              symbols = { modified = '' },
              show_modified_status = false,
              fmt = function(name, context)
                local buflist = vim.fn.tabpagebuflist(context.tabnr)
                local winnr = vim.fn.tabpagewinnr(context.tabnr)
                local bufnr = buflist[winnr]
                local mod = vim.fn.getbufvar(bufnr, '&mod')
                local name_hl = mod == 1 and '%#MatchParen#' or ''
                if name == '[No Name]' then
                  name = context.filetype
                end

                return name_hl .. name
              end,
            },
          },
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
