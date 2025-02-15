return {
  {
    'folke/trouble.nvim',
    lazy = true,
    opts = {},
    cmd = 'Trouble',
    dependencies = { 'echasnovski/mini.nvim' },
    keys = {
      {
        '<leader>x',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Toggle Trouble',
      },
    },
  },
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    priority = 1000,
    opts = {},
    init = function()
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
  ---@module 'neotest'
  {
    'nvim-neotest/neotest',
    cmd = 'Neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-neotest/neotest-plenary',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'fredrikaverpil/neotest-golang',
      'marilari88/neotest-vitest',
      'mrcjkb/rustaceanvim',
    },
    opts = function()
      return {
        ---@type neotest.Config|{}
        adapters = {
          require 'neotest-golang',
          require 'neotest-vitest',
          require 'neotest-plenary',
          require 'rustaceanvim.neotest',
        },
      }
    end,
    keys = {
      { '<leader>tn', function() require('neotest').run.run() end,                   desc = '[T]est [N]earest' },
      { '<leader>ta', function() require('neotest').run.run(vim.uv.cwd()) end,       desc = '[T]est [A]ll' },
      { '<leader>tb', function() require('neotest').run.run(vim.fn.expand("%")) end, desc = '[T]est Current [B]uffer' },
      { '<leader>ts', function() require('neotest').summary.toggle() end,            desc = '[T]est [S]ummary' },
    },
  },
  {
    'mfussenegger/nvim-dap',
    enabled = false,
    event = 'VeryLazy',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      { 'theHamsta/nvim-dap-virtual-text', opts = {} },
      'nvim-neotest/nvim-nio',
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',
      'leoluz/nvim-dap-go',
    },
    keys = function(_, keys)
      local dap = require 'dap'
      local dapui = require 'dapui'
      return {
        { '<F5>',      dap.continue,          desc = 'Debug: Start/Continue' },
        { '<F1>',      dap.step_into,         desc = 'Debug: Step Into' },
        { '<F2>',      dap.step_over,         desc = 'Debug: Step Over' },
        { '<F3>',      dap.step_out,          desc = 'Debug: Step Out' },
        { '<leader>b', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
        {
          '<leader>B',
          function()
            dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
          end,
          desc = 'Debug: Set Breakpoint',
        },
        -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
        { '<F7>', dapui.toggle, desc = 'Debug: See last session result.' },
        unpack(keys),
      }
    end,
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('mason-nvim-dap').setup {
        automatic_installation = true,
        handlers = {},
        ensure_installed = {
          'delve',
        },
      }

      dapui.setup {
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      }

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      require('dap-go').setup {
        delve = {
          -- On Windows delve must be run attached or it crashes.
          -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
          detached = vim.fn.has 'win32' == 0,
        },
      }
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
