-- Clear search on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', function()
  vim.schedule(function()
    vim.cmd.nohlsearch()
  end)
  if package.loaded['noice'] then
    require('noice').cmd 'dismiss'
  end
end, { silent = true })

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
local function toggle_harper_ls()
  local globally_enabled = vim.lsp.is_enabled 'harper_ls'
  if globally_enabled then
    vim.lsp.enable('harper_ls', false)
    vim.notify('harper_ls spellcheck disabled', vim.log.levels.INFO)
  else
    vim.lsp.enable('harper_ls', true)
    vim.notify('harper_ls spellcheck enabled', vim.log.levels.INFO)
  end
end

vim.keymap.set('n', '<leader>th', toggle_harper_ls, {
  desc = '[T]oggle [h]arper_ls spellcheck',
})

-- Toggle diagnostics
vim.keymap.set('n', '<leader>tD', function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = '[T]oggle [D]iagnostics' })
-- vim: ts=2 sts=2 sw=2 et
