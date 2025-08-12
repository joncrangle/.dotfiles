return {
  { 'NMAC427/guess-indent.nvim', opts = {} },
  {
    'folke/trouble.nvim',
    lazy = true,
    opts = {},
    cmd = 'Trouble',
    dependencies = { 'echasnovski/mini.nvim' },
    keys = {
      { '<leader>x', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Toggle Trouble' },
    },
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
    -- stylua: ignore
    keys = {
      { '<leader>tn', function() require('neotest').run.run() end,                  desc = '[T]est [N]earest' },
      { '<leader>ta', function() require('neotest').run.run(vim.uv.cwd()) end,      desc = '[T]est [A]ll' },
      { '<leader>tb', function() require('neotest').run.run(vim.fn.expand '%') end, desc = '[T]est Current [B]uffer' },
      { '<leader>ts', function() require('neotest').summary.toggle() end,           desc = '[T]est [S]ummary' },
    },
  },
  {
    'mfussenegger/nvim-dap',
    enabled = false,
    event = 'VeryLazy',
    dependencies = {
      {
        'igorlfs/nvim-dap-view',
        opts = { winbar = { controls = { enabled = true } } },
        keys = function(_, keys)
          local dap = require 'dap'
          return {
            { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },
            { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
            { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
            { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
            { '<leader>db', dap.toggle_breakpoint, desc = '[D]ebug: Toggle [B]reakpoint' },
            {
              '<leader>dc',
              function()
                dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
              end,
              desc = '[D]ebug: Set [C]ondition Breakpoint',
            },
            { '<F7>', '<cmd>DapViewToggle<cr>', desc = 'Toggle DAP View' },
            unpack(keys),
          }
        end,
      },
      { 'theHamsta/nvim-dap-virtual-text', opts = {} },
      'nvim-neotest/nvim-nio',
      'jay-babu/mason-nvim-dap.nvim',
      'leoluz/nvim-dap-go',
    },
    config = function()
      local dap = require 'dap'

      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpoint', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapBreakpointCondition', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DapBreakpointRejected', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped', numhl = '' })

      require('mason-nvim-dap').setup {
        automatic_installation = true,
        handlers = {},
        ensure_installed = {
          'delve',
          'js-debug-adapter',
        },
      }

      if not dap.adapters['pwa-node'] then
        dap.adapters['pwa-node'] = {
          type = 'server',
          host = 'localhost',
          port = '${port}',
          executable = {
            command = 'node',
            args = {
              vim.env.MASON .. '/packages/' .. 'js-debug-adapter' .. '/js-debug/src/dapDebugServer.js',
              '${port}',
            },
          },
        }
      end
      for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
        if not dap.configurations[language] then
          dap.configurations[language] = {
            {
              type = 'pwa-node',
              request = 'launch',
              name = 'Launch file',
              program = '${file}',
              cwd = '${workspaceFolder}',
            },
            {
              type = 'pwa-node',
              request = 'attach',
              name = 'Attach',
              processId = require('dap.utils').pick_process,
              cwd = '${workspaceFolder}',
            },
          }
        end
      end

      require('dap-go').setup {
        delve = {
          -- On Windows delve must be run attached or it crashes.
          -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
          detached = vim.fn.has 'win32' == 0,
        },
      }
    end,
  },
  {
    'MagicDuck/grug-far.nvim',
    opts = { headerMaxWidth = 80 },
    cmd = { 'GrugFar', 'GrugFarWithin' },
    keys = {
      {
        '<leader>sr',
        function()
          local grug = require 'grug-far'
          local ext = vim.bo.buftype == '' and vim.fn.expand '%:e'
          grug.open {
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
            },
          }
        end,
        mode = { 'n', 'v' },
        desc = '[S]earch and [R]eplace',
      },
    },
  },
  {
    'sahilsehwag/macrobank.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
    keys = function()
      local wk = require 'which-key'
      -- stylua: ignore
      wk.add({
        { '<leader>m', group = '[M]acro', icon = { icon = '󰑙', color = 'green' } },
        { '<leader>me', function() require('macrobank.bank_editor').open() end, desc = '[M]acrobank Saved Macros' },
        { '<leader>mm', function() require('macrobank.editor').open() end, desc = '[M]acrobank Live Macros' },
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
