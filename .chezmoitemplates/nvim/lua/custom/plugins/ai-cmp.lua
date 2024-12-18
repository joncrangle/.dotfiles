return {
  {
    'zbirenbaum/copilot.lua',
    enabled = true,
    cmd = 'Copilot',
    build = ':Copilot auth',
    event = 'InsertEnter',
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = '<Tab>',
          next = ']]',
          prev = '[[',
        },
      },
      panel = { enabled = false },
      filetypes = {
        yaml = true,
        markdown = true,
        help = true,
      },
    },
  },
  {
    'Exafunction/codeium.vim',
    enabled = false,
    lazy = true,
    event = 'InsertEnter',
    cmd = 'Codeium',
    build = ':Codeium Auth',
    init = function()
      vim.g.codeium_filetypes = {
        oil = false,
        TelescopePrompt = false,
        NeoTree = false,
        AvanteInput = false,
      }
    end,
    config = function()
      vim.g.codeium_disable_bindings = true
      vim.g.codeium_enabled = true
      vim.keymap.set('i', '<Tab>', function()
        return vim.fn['codeium#Accept']()
      end, { expr = true, silent = true, desc = 'Codeium Accept' })
      vim.keymap.set('i', ']]', function()
        return vim.fn['codeium#CycleCompletions'](1)
      end, { expr = true, silent = true, desc = 'Codeium Next Completion' })
      vim.keymap.set('i', '[[', function()
        return vim.fn['codeium#CycleCompletions'](-1)
      end, { expr = true, silent = true, desc = 'Codeium Previous Completion' })
      vim.keymap.set('i', '<C-x>', function()
        return vim.fn['codeium#Clear']()
      end, { expr = true, silent = true, desc = 'Codeium Clear' })
      vim.keymap.set('i', '<C-\\>', function()
        return vim.fn['codeium#Complete']()
      end, { expr = true, silent = true, desc = 'Codeium Trigger Completion' })
      vim.keymap.set('n', '<leader>cc', function()
        return vim.fn['codeium#Chat']()
      end, { desc = '  [C]hat with [C]odeium' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
