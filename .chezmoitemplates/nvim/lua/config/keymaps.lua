-- Clear search on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-q>', '<cmd>tabclose<CR>', { desc = 'Close tab page' })

-- Replace current word
vim.keymap.set('n', '<leader>rw', ':%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>', { desc = '[R]eplace current [w]ord' })

-- Keep cursor in place when joining lines, moving, or searching
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Page down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Page up' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result' })

-- Paste and delete without yanking
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Paste without yanking' })
vim.keymap.set('n', '<leader>d', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set('v', '<leader>d', '"_d', { desc = 'Delete without yanking' })
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete without yanking' })
vim.keymap.set('v', 'x', '"_x', { desc = 'Delete without yanking' })

-- In visual mode, move highlighted text up or down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move highlighted text up' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move highlighted text down' })

-- Toggle harper_ls spellcheck
local function toggle_harper_spellcheck()
  local bufnr = vim.api.nvim_get_current_buf()

  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.name == 'harper_ls' then
      ---@diagnostic disable-next-line:param-type-mismatch
      client.stop(true)
      vim.notify('harper_ls spellcheck disabled', vim.log.levels.INFO)
      return
    end
  end

  require('lspconfig').harper_ls.setup {}

  vim.lsp.start {
    name = 'harper_ls',
    cmd = require('lspconfig').harper_ls.cmd,
    root_dir = require('lspconfig').util.root_pattern '.git'(vim.api.nvim_buf_get_name(bufnr)) or vim.fn.getcwd(),
  }

  vim.notify('harper_ls spellcheck enabled', vim.log.levels.INFO)
end
vim.keymap.set('n', '<leader>th', toggle_harper_spellcheck, { desc = '[T]oggle [h]arper_ls spellcheck' })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('close-with-q', { clear = true }),
  pattern = {
    'PlenaryTestPopup',
    'Avante',
    'AvanteInput',
    'AvanteSelectedFiles',
    'checkhealth',
    'dbout',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'startuptime',
    'tsplayground',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})
-- vim: ts=2 sts=2 sw=2 et
